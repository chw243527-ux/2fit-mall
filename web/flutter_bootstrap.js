{{flutter_build_config}}

// Flutter loader가 외부 스크립트·서비스워커·브라우저 초기화 순서와 경합할 수 있어
// 첫 실행에서 flutter-view가 생성되지 않으면 한 번만 안전하게 재시도합니다.
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
