{{flutter_js}}
{{flutter_build_config}}

// canvaskit 렌더러 고정: 모든 브라우저에서 동일한 고품질 렌더링
// skwasm(기본값) 대신 canvaskit을 명시해 이미지·텍스트 깨짐 방지
_flutter.loader.load({
  onEntrypointLoaded: async function(engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine({
      renderer: 'canvaskit',
    });
    await appRunner.runApp();
  }
});
