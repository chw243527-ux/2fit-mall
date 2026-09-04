{{flutter_js}}
{{flutter_build_config}}

// 브라우저 환경에 맞는 Flutter 기본 렌더러를 사용합니다.
// 특정 렌더러를 강제하지 않아 CanvasKit/Skwasm 호환성 문제를 피합니다.
_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
  }
});
