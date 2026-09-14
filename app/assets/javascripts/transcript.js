// Prototype: polls /radios/:id/transcript for locally-generated live
// speech-to-text lines (their pinyin romanization, for Chinese stations,
// and their Spanish translation - see transcriber/transcribe.py) and
// appends them to both the transcript and translation panels in lockstep.
// Only ever has content for whichever single station the transcriber
// script is currently pointed at - everywhere else this just stays empty.
//
// Transcription runs much faster than real-time (a 10s chunk transcribes in
// well under a second), so a line's started_at is already in the past by
// the time it reaches the browser - there's no such thing as "the future"
// from the client's point of view. Meanwhile the audio a listener is
// actually hearing is delayed by the <audio> element's own playback
// buffering, which JS can't read for a live stream. So instead of matching
// wall-clock time directly (which just always picks the newest line - it's
// always already in the past), the "current" line is the most recent one
// whose started_at is at least PLAYBACK_DELAY_MS old. That's a guess at
// typical buffering delay, not a measurement, so this trails behind
// already-visible text by a rough approximation rather than exact sync.
(function() {
  var CURRENT_ROW = 5; // 1-indexed row, within the 7-row window, kept as "current"
  var VISIBLE_ROWS = 7;
  var PLAYBACK_DELAY_MS = 15000;
  var DEFAULT_POLL_INTERVAL_MS = 3000;

  // UTC, not the browser's local time zone: started_at is captured
  // server-side as UTC, and transcriber/transcribe.py's own terminal
  // output prints that same UTC clock - matching it here means the
  // timestamps you see in both places line up.
  function formatUtcTime(date) {
    function pad(n) { return (n < 10 ? "0" : "") + n; }
    return pad(date.getUTCHours()) + ":" + pad(date.getUTCMinutes()) + ":" + pad(date.getUTCSeconds());
  }

  // Builds one entry: a wrapper <div class="transcript-entry"> holding a
  // primary <p class="transcript-line"> and, when pinyinText is given, a
  // second indented <p class="transcript-pinyin"> below it. A Chinese entry
  // is therefore two rows tall where an English one is one - the scroll
  // math below accounts for that rather than assuming a uniform row height.
  function buildEntry(mainText, pinyinText) {
    var entry = document.createElement("div");
    entry.className = "transcript-entry upcoming";

    var line = document.createElement("p");
    line.className = "transcript-line";
    line.textContent = mainText;
    entry.appendChild(line);

    if (pinyinText) {
      var pinyinLine = document.createElement("p");
      pinyinLine.className = "transcript-pinyin";
      pinyinLine.textContent = pinyinText;
      entry.appendChild(pinyinLine);
    }

    return entry;
  }

  // targetEl: transcript panel (required). translationEl: Spanish
  // translation panel (optional - pass null to skip it entirely).
  function startTranscriptPolling(transcriptUrl, targetEl, translationEl, intervalMs) {
    var sinceId = 0;
    var lines = []; // { el, translationEl, startedAt }

    function poll() {
      var url = transcriptUrl + (transcriptUrl.indexOf("?") === -1 ? "?" : "&") + "since_id=" + sinceId;
      fetch(url, { headers: { "Accept": "application/json" } })
        .then(function(response) { return response.ok ? response.json() : null; })
        .then(function(data) {
          if (!data || !data.lines || data.lines.length === 0) return;

          data.lines.forEach(function(line) {
            sinceId = Math.max(sinceId, line.id);
            var startedAt = line.started_at ? new Date(line.started_at) : null;
            var prefix = startedAt ? "[" + formatUtcTime(startedAt) + "] " : "";

            var entry = buildEntry(prefix + line.text, line.pinyin);
            targetEl.appendChild(entry);

            var translationEntry = null;
            if (translationEl) {
              translationEntry = buildEntry(prefix + (line.translated_text || "…"), null);
              translationEl.appendChild(translationEntry);
            }

            lines.push({ el: entry, translationEl: translationEntry, startedAt: startedAt });
          });
          targetEl.hidden = false;
          if (translationEl) translationEl.hidden = false;
          highlightCurrentLine();
        })
        .catch(function(err) {
          console.error("RadioGuguTranscript poll failed:", err);
        });
    }

    function highlightCurrentLine() {
      var playbackNow = new Date(Date.now() - PLAYBACK_DELAY_MS);

      var currentIndex = -1;
      lines.forEach(function(line, i) {
        if (line.startedAt && line.startedAt <= playbackNow) currentIndex = i;
      });

      lines.forEach(function(line, i) {
        var state = i < currentIndex ? "past" : (i === currentIndex ? "current" : "upcoming");
        line.el.className = "transcript-entry " + state;
        if (line.translationEl) line.translationEl.className = "transcript-entry " + state;
      });

      if (currentIndex >= 0) {
        scrollToCurrent(targetEl, lines, currentIndex, function(l) { return l.el; });
        if (translationEl) scrollToCurrent(translationEl, lines, currentIndex, function(l) { return l.translationEl; });
      }
    }

    function scrollToCurrent(panelEl, lines, currentIndex, getEl) {
      // The panel's fixed total height is always VISIBLE_ROWS single-line
      // rows, measured off the current entry's primary line (always
      // exactly one row) - not its full height, which may include a
      // pinyin row.
      var currentEntryEl = getEl(lines[currentIndex]);
      var primaryLine = currentEntryEl.querySelector(".transcript-line") || currentEntryEl;
      var rowHeight = primaryLine.offsetHeight;
      panelEl.style.height = (VISIBLE_ROWS * rowHeight) + "px";

      // Scroll position: the panel's scrollTop needs to be the ABSOLUTE
      // cumulative height of every entry before the first one that should
      // be visible - not just the height of that handful of entries
      // themselves. (Bug fixed here: this used to sum only the
      // CURRENT_ROW-1 entries immediately before the current one, which
      // is the right idea for a *relative* offset but was being assigned
      // directly as scrollTop, an *absolute* one - correct only for the
      // first few entries of a session, silently wrong for any long
      // history, where it always parked the view near the very top.)
      var firstVisibleIndex = Math.max(0, currentIndex - (CURRENT_ROW - 1));
      var targetTop = 0;
      for (var i = 0; i < firstVisibleIndex; i++) {
        targetTop += getEl(lines[i]).offsetHeight;
      }
      panelEl.scrollTop = Math.max(0, targetTop);
    }

    // Chrome (more aggressively than Firefox) throttles/pauses setInterval
    // timers in tabs that lose focus, so polling can silently stop while
    // you're looking at another window - the server keeps producing data
    // fine the whole time, the display just stops catching up. Force an
    // immediate resync the moment the tab becomes visible again rather
    // than waiting for a possibly-throttled timer to resume on its own.
    function onVisible() {
      if (document.visibilityState === "visible") {
        poll();
        highlightCurrentLine();
      }
    }
    document.addEventListener("visibilitychange", onVisible);

    poll();
    var pollTimer = setInterval(poll, intervalMs || DEFAULT_POLL_INTERVAL_MS);
    var clockTimer = setInterval(highlightCurrentLine, 1000);
    return function stop() {
      clearInterval(pollTimer);
      clearInterval(clockTimer);
      document.removeEventListener("visibilitychange", onVisible);
    };
  }

  window.RadioGuguTranscript = { start: startTranscriptPolling };
})();
