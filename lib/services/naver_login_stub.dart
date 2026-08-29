// naver_login_stub.dart — Web 빌드용 스텁 (flutter_naver_login은 Web 미지원)
// flutter_naver_login 2.1.1 API 시그니처와 동일하게 맞춤

class FlutterNaverLogin {
  static Future<void> initSdk({
    required String clientId,
    required String clientSecret,
    required String clientName,
    bool enableNaverAppAuthIOS = true,
  }) async {}

  static Future<NaverLoginResult> logIn() async {
    return NaverLoginResult(status: NaverLoginStatus.error, account: null, errorMessage: 'Web not supported');
  }

  static Future<NaverLoginResult> logOut() async {
    return NaverLoginResult(status: NaverLoginStatus.loggedOut, account: null, errorMessage: '');
  }

  static Future<NaverLoginResult> logOutAndDeleteToken() async {
    return NaverLoginResult(status: NaverLoginStatus.loggedOut, account: null, errorMessage: '');
  }

  static Future<NaverAccountResult> getCurrentAccount() async {
    return NaverAccountResult(
      id: '', email: '', name: '', nickname: '',
      profileImage: '', age: '', gender: '', birthday: '',
    );
  }
}

enum NaverLoginStatus { loggedIn, loggedOut, error }

class NaverLoginResult {
  final NaverLoginStatus status;
  final NaverAccountResult? account;
  final String errorMessage;
  NaverLoginResult({
    required this.status,
    required this.account,
    required this.errorMessage,
  });
}

class NaverAccountResult {
  final String id;
  final String email;
  final String name;
  final String nickname;
  final String profileImage;
  final String age;
  final String gender;
  final String birthday;
  NaverAccountResult({
    required this.id,
    required this.email,
    required this.name,
    required this.nickname,
    required this.profileImage,
    required this.age,
    required this.gender,
    required this.birthday,
  });
}
