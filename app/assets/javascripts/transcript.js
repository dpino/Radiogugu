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
        if (i < currentIndex) line.el.className = "transcript-line past";
        else if (i === currentIndex) line.el.className = "transcript-line current";
        else line.el.className = "transcript-line upcoming";
      });

      if (currentIndex >= 0) {
        lines[currentIndex].el.scrollIntoView({ block: "nearest" });
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
