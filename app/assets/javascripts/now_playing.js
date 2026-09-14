// Polls our own /radios/:id/now_playing endpoint (see IcyNowPlaying and
// RadiosController#now_playing) for the track title, and writes it into
// targetEl. Not every station can report one - the endpoint returns
// {title: null} when it can't, and this just stays quiet in that case
// rather than showing an error.
(function() {
  function startNowPlayingPolling(nowPlayingUrl, targetEl, intervalMs) {
    function poll() {
      fetch(nowPlayingUrl, { headers: { "Accept": "application/json" } })
        .then(function(response) { return response.ok ? response.json() : null; })
        .then(function(data) {
          if (data && data.title) {
            targetEl.textContent = "Now playing: " + data.title;
            targetEl.hidden = false;
          }
        })
        .catch(function() {});
    }

    poll();
    var timer = setInterval(poll, intervalMs || 20000);
    return function stop() {
      clearInterval(timer);
    };
  }

  window.RadioGuguNowPlaying = { start: startNowPlayingPolling };
})();
