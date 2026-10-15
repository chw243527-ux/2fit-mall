{{flutter_js}}
{{flutter_build_config}}

// Flutter 표준 web bootstrap: 엔진 주입 후 build config를 적용하고 앱을 시작합니다.
(function () {
  // 초기화가 느린 기기에서 엔진을 다시 실행하면 Flutter 앱이 중복
  // 마운트되어 iOS Safari에서 페이지 반복 오류가 발생할 수 있습니다.
  // 로더는 페이지당 한 번만 실행하고, 실패 시 로딩 fallback이 안내합니다.
  if (window.__flutterBootstrapStarted || window.__flutterBootstrapLoading) return;
  window.__flutterBootstrapLoading = true;

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
})();
