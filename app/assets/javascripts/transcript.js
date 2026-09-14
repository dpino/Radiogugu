// Prototype: polls /radios/:id/transcript for locally-generated live
// speech-to-text lines (and their Spanish translation - see
// transcriber/transcribe.py) and appends them to both the transcript and
// translation panels in lockstep. Only ever has content for whichever
// single station the transcriber script is currently pointed at -
// everywhere else this just stays empty.
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

            var p = document.createElement("p");
            p.className = "transcript-line upcoming";
            p.textContent = prefix + line.text;
            targetEl.appendChild(p);

            var translationP = null;
            if (translationEl) {
              translationP = document.createElement("p");
              translationP.className = "transcript-line upcoming";
              translationP.textContent = prefix + (line.translated_text || "…");
              translationEl.appendChild(translationP);
            }

            lines.push({ el: p, translationEl: translationP, startedAt: startedAt });
          });
          targetEl.hidden = false;
          if (translationEl) translationEl.hidden = false;
          highlightCurrentLine();
        })
        .catch(function() {});
    }

    function highlightCurrentLine() {
      var playbackNow = new Date(Date.now() - PLAYBACK_DELAY_MS);

      var currentIndex = -1;
      lines.forEach(function(line, i) {
        if (line.startedAt && line.startedAt <= playbackNow) currentIndex = i;
      });

      lines.forEach(function(line, i) {
        var className;
        if (i < currentIndex) className = "transcript-line past";
        else if (i === currentIndex) className = "transcript-line current";
        else className = "transcript-line upcoming";

        line.el.className = className;
        if (line.translationEl) line.translationEl.className = className;
      });

      if (currentIndex >= 0) {
        scrollToCurrent(targetEl, lines, currentIndex, function(l) { return l.el; });
        if (translationEl) scrollToCurrent(translationEl, lines, currentIndex, function(l) { return l.translationEl; });
      }
    }

    function scrollToCurrent(panelEl, lines, currentIndex, getEl) {
      var rowHeight = getEl(lines[currentIndex]).offsetHeight;
      panelEl.style.height = (VISIBLE_ROWS * rowHeight) + "px";
      var targetTop = (currentIndex - (CURRENT_ROW - 1)) * rowHeight;
      panelEl.scrollTop = Math.max(0, targetTop);
    }

    poll();
    var pollTimer = setInterval(poll, intervalMs || DEFAULT_POLL_INTERVAL_MS);
    var clockTimer = setInterval(highlightCurrentLine, 1000);
    return function stop() {
      clearInterval(pollTimer);
      clearInterval(clockTimer);
    };
  }

  window.RadioGuguTranscript = { start: startTranscriptPolling };
})();
