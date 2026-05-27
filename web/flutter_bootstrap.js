{{flutter_js}}
{{flutter_build_config}}

// HtmlElementView(비디오 배너) 정상 렌더링을 위해 html 렌더러 강제 지정
// buildConfig의 renderer를 런타임에 html로 덮어쓰기
(function() {
  if (window._flutter && window._flutter.buildConfig) {
    var builds = window._flutter.buildConfig.builds;
    if (builds && builds.length > 0) {
      for (var i = 0; i < builds.length; i++) {
        builds[i].renderer = "html";
      }
    }
  }
})();

_flutter.loader.load({
  config: {
    renderer: "html",
  },
});
