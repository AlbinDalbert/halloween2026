// Connects the LiveViews. phoenix.min.js and phoenix_live_view.min.js are served from the deps
// and define the `Phoenix` and `LiveView` globals, so there is no build step.
(function () {
  const hooks = {
    // Counts down to data-at, so every screen shows the same time left without the server
    // sending a tick each second.
    Countdown: {
      mounted() {
        this.tick();
        this.timer = setInterval(() => this.tick(), 250);
      },
      updated() {
        this.tick();
      },
      destroyed() {
        clearInterval(this.timer);
      },
      tick() {
        const left = Math.max(0, Math.ceil((Date.parse(this.el.dataset.at) - Date.now()) / 1000));
        this.el.textContent = left;
        this.el.classList.toggle("urgent", left <= 5);
      },
    },

    // Buzzes the phone when a new card lands on stage (data-key changes).
    Buzz: {
      mounted() {
        this.key = this.el.dataset.key;
      },
      updated() {
        if (this.el.dataset.key !== this.key) {
          this.key = this.el.dataset.key;
          if (this.key && navigator.vibrate) navigator.vibrate([90, 60, 90]);
        }
      },
    },

    // Keeps the TV's screen from going to sleep.
    WakeLock: {
      mounted() {
        const lock = () => navigator.wakeLock?.request("screen").catch(() => {});
        lock();
        document.addEventListener("visibilitychange", () => {
          if (document.visibilityState === "visible") lock();
        });
      },
    },
  };

  const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
  const liveSocket = new LiveView.LiveSocket("/live", Phoenix.Socket, {
    params: { _csrf_token: csrfToken },
    hooks,
  });

  liveSocket.connect();
  window.liveSocket = liveSocket;
})();
