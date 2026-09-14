// Prototype: polls /radios/:id/transcript for locally-generated live
// speech-to-text lines (see transcriber/transcribe.py) and appends them to
// targetEl. Only ever has content for whichever single station the
// transcriber script is currently pointed at - everywhere else this just
// stays empty.
//
// Transcription runs much faster than real-time (a 10s chunk transcribes in
// well under a second), so new lines land well ahead of what a listener is
// actually hearing. Rather than hide that, every line is shown as soon as
// it arrives, but only the most recent one whose started_at has actually
// been reached by the wall clock is highlighted as "current" - everything
// after it is visibly upcoming, not yet "reached". This tracks the
// server's own capture clock, not the listener's actual (buffered)
// playback position, so it's an approximation of "what's playing now", not
// frame-accurate sync.
(function() {
  // The current line is kept at this row within the 7-row window (1-indexed):
  // 4 lines of past context above it, the current line, 2 lines of upcoming
  // text below it.
  var CURRENT_ROW = 5;
  var VISIBLE_ROWS = 7;

  function startTranscriptPolling(transcriptUrl, targetEl, intervalMs) {
    var sinceId = 0;
    var lines = []; // { el, startedAt, endedAt }

    function poll() {
      var url = transcriptUrl + (transcriptUrl.indexOf("?") === -1 ? "?" : "&") + "since_id=" + sinceId;
      fetch(url, { headers: { "Accept": "application/json" } })
        .then(function(response) { return response.ok ? response.json() : null; })
        .then(function(data) {
          if (!data || !data.lines || data.lines.length === 0) return;

          data.lines.forEach(function(line) {
            sinceId = Math.max(sinceId, line.id);
            var p = document.createElement("p");
            p.className = "transcript-line upcoming";
            p.textContent = line.text;
            targetEl.appendChild(p);
            lines.push({
              el: p,
              startedAt: line.started_at ? new Date(line.started_at) : null,
              endedAt: line.ended_at ? new Date(line.ended_at) : null,
            });
          });
          targetEl.hidden = false;
          highlightCurrentLine();
        })
        .catch(function() {});
    }

    function highlightCurrentLine() {
      var now = new Date();

      // "Current" = the most recent line whose started_at the wall clock has
      // reached - not "now falls inside [started_at, ended_at]", since
      // there's a real gap between chunks (ffmpeg + transcription
      // overhead) that a window-based check would fall into, leaving
      // nothing highlighted at all.
      var currentIndex = -1;
      lines.forEach(function(line, i) {
        if (line.startedAt && line.startedAt <= now) currentIndex = i;
      });

      lines.forEach(function(line, i) {
        var className;
        if (i < currentIndex) className = "transcript-line past";
        else if (i === currentIndex) className = "transcript-line current";
        else className = "transcript-line upcoming";

        // Fade by distance from the current line, capped at 4 (the number
        // of past rows visible in the 7-row window) so anything further off
        // screen just stays at the most-faded step rather than going
        // fully transparent.
        var distance = Math.min(4, Math.abs(i - currentIndex));
        if (distance > 0) className += " dist-" + distance;

        line.el.className = className;
      });

      if (currentIndex >= 0) {
        var rowHeight = lines[currentIndex].el.offsetHeight;
        targetEl.style.height = (VISIBLE_ROWS * rowHeight) + "px";
        var targetTop = (currentIndex - (CURRENT_ROW - 1)) * rowHeight;
        targetEl.scrollTop = Math.max(0, targetTop);
      }
    }

    poll();
    var pollTimer = setInterval(poll, intervalMs || 8000);
    var clockTimer = setInterval(highlightCurrentLine, 1000);
    return function stop() {
      clearInterval(pollTimer);
      clearInterval(clockTimer);
    };
  }

  window.RadioGuguTranscript = { start: startTranscriptPolling };
})();
