// Prototype: polls /radios/:id/transcript for locally-generated live
// speech-to-text lines (see transcriber/transcribe.py) and appends them to
// targetEl. Only ever has content for whichever single station the
// transcriber script is currently pointed at - everywhere else this just
// stays empty.
(function() {
  function startTranscriptPolling(transcriptUrl, targetEl, intervalMs) {
    var sinceId = 0;

    function poll() {
      var url = transcriptUrl + (transcriptUrl.indexOf("?") === -1 ? "?" : "&") + "since_id=" + sinceId;
      fetch(url, { headers: { "Accept": "application/json" } })
        .then(function(response) { return response.ok ? response.json() : null; })
        .then(function(data) {
          if (!data || !data.lines || data.lines.length === 0) return;

          data.lines.forEach(function(line) {
            sinceId = Math.max(sinceId, line.id);
            var p = document.createElement("p");
            p.textContent = line.text;
            targetEl.appendChild(p);
          });
          targetEl.hidden = false;
          targetEl.scrollTop = targetEl.scrollHeight;
        })
        .catch(function() {});
    }

    poll();
    var timer = setInterval(poll, intervalMs || 8000);
    return function stop() {
      clearInterval(timer);
    };
  }

  window.RadioGuguTranscript = { start: startTranscriptPolling };
})();
