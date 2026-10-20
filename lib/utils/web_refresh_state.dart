// 웹 새로고침 시 마지막 화면을 복원하기 위한 플랫폼 공통 API.
// 모바일에서는 아무 동작도 하지 않습니다.
Map<String, dynamic>? readWebRouteState() => null;
void saveWebRouteState(String route, Map<String, String> arguments) {}

// 이전 상품 상세 복원 코드와의 호환용 API.
void saveWebRefreshState(String state) {}
String? readWebRefreshState() => null;
void clearWebRefreshState() {}
