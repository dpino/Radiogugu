// Prototype: polls /radios/:id/transcript for locally-generated live
// speech-to-text lines (see transcriber/transcribe.py) and appends them to
// targetEl. Only ever has content for whichever single station the
// transcriber script is currently pointed at - everywhere else this just
// stays empty.
//
// Transcription runs much faster than real-time (a 10s chunk transcribes in
// well under a second), so new lines land well ahead of what a listener is
// actually hearing. Rather than hide that, every line is shown as soon as
// it arrives, but only the one whose [started_at, ended_at] window contains
// the current wall-clock time is highlighted as "current" - everything
// after it is visibly upcoming, not yet "reached". This tracks the
// server's own capture clock, not the listener's actual (buffered)
// playback position, so it's an approximation, not frame-accurate sync.
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
      var current = null;

      lines.forEach(function(line) {
        if (!line.startedAt) return;

        if (line.startedAt <= now && (!line.endedAt || now <= line.endedAt)) {
          current = line;
        } else if (line.startedAt <= now) {
          line.el.className = "transcript-line past";
        } else {
          line.el.className = "transcript-line upcoming";
        }
      });

      if (current) {
        current.el.className = "transcript-line current";
        current.el.scrollIntoView({ block: "nearest" });
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
