{{flutter_js}}
{{flutter_build_config}}

// Flutter 표준 web bootstrap: 엔진 주입 후 build config를 적용하고 앱을 시작합니다.
(function () {
  let attempts = 0;
  const maxAttempts = 2;

  function startFlutter() {
    if (attempts >= maxAttempts) return;
    attempts += 1;
    window.__flutterBootstrapAttempts = attempts;

    _flutter.loader.load({
      onEntrypointLoaded: async function (engineInitializer) {
        try {
          const appRunner = await engineInitializer.initializeEngine();
          await appRunner.runApp();
          window.__flutterBootstrapStarted = true;
        } catch (error) {
          window.__flutterBootstrapError = String(error && (error.stack || error));
          console.error('[2FIT] Flutter app startup failed:', error);
        }
      }
    }).catch(function (error) {
      window.__flutterBootstrapError = String(error && (error.stack || error));
      console.error('[2FIT] Flutter loader failed:', error);
    });
  }

  startFlutter();
  window.setTimeout(function () {
    if (!document.querySelector('flutter-view') && attempts < maxAttempts) {
      startFlutter();
    }
  }, 5000);
})();
