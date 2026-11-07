{{flutter_js}}
{{flutter_build_config}}

// Eigener Start statt des mitgelieferten (Issue #135): Er meldet dem
// Ladebildschirm in index.html, wie weit es ist.
(function () {
  function melde(wert, decke) {
    if (window.lifesGameLaden) window.lifesGameLaden(wert, decke);
  }
  _flutter.loader.load({
    serviceWorkerSettings: {
      serviceWorkerVersion: {{flutter_service_worker_version}},
    },
    onEntrypointLoaded: async function (engineInitializer) {
      melde(0.45, 0.8);
      const appRunner = await engineInitializer.initializeEngine();
      melde(0.8, 0.95);
      await appRunner.runApp();
      melde(0.95, 0.99);
    },
  });
})();
