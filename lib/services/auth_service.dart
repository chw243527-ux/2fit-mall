// auth_service.dart — Firebase Auth 기반 (이메일/비밀번호)
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
// 웹 JS interop
import 'naver_web_stub.dart' if (dart.library.html) 'naver_web_login.dart'
    as naverWeb;
import '../models/models.dart';

class AuthService {
  static const _sessionBox = 'session';
  static const _sessionVersionKey = 'authSessionVersion';
  static const _rememberedEmailsKeyPrefix = 'rememberedEmails';
  static const _legacyRememberedEmailsKey = 'rememberedEmails';
  static const _legacyRememberMeEmailKey = 'rememberMeEmail';
  static const _deviceScopeStorageKey = 'deviceInstallationScope';
  static final FlutterSecureStorage _deviceStorage = FlutterSecureStorage();
  static String? _deviceScope;
  static Future<String>? _deviceScopeInFlight;
  static Completer<Map<String, String>>? _naverMobileCodeWaiter;
  static Future<AuthResult>? _restoreSessionInFlight;
  static final Completer<bool> _firebaseReady = Completer<bool>();
  static const _naverRedirectUri =
      'https://2fit-mall.co.kr/naver_callback.html';

  static void handleNaverDeepLink(Uri uri) {
    if (uri.scheme != 'twofitmall' || uri.host != 'naver') return;
    final waiter = _naverMobileCodeWaiter;
    if (waiter == null || waiter.isCompleted) return;
    final code = uri.queryParameters['code'] ?? '';
    final state = uri.queryParameters['state'] ?? '';
    if (code.isEmpty || state.isEmpty) {
      waiter.completeError(StateError('네이버 인증 코드가 없습니다.'));
      return;
    }
    waiter.complete(
        {'code': code, 'state': state, 'redirectUri': _naverRedirectUri});
  }

  static Future<Map<String, String>> _waitForNaverMobileCode() {
    final waiter = Completer<Map<String, String>>();
    _naverMobileCodeWaiter = waiter;
    return waiter.future
        .timeout(
      const Duration(minutes: 5),
      onTimeout: () => throw TimeoutException('네이버 로그인 시간이 만료되었습니다.'),
    )
        .whenComplete(() {
      if (identical(_naverMobileCodeWaiter, waiter))
        _naverMobileCodeWaiter = null;
    });
  }

  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static Future<Box> _getSessionBox() async {
    if (Hive.isBoxOpen(_sessionBox)) return Hive.box(_sessionBox);
    return await Hive.openBox(_sessionBox);
  }

  /// secure storage에 설치별 식별자를 저장해 아이디 저장값을 기기별로 격리합니다.
  static Future<String> _getDeviceScope() {
    final cached = _deviceScope;
    if (cached != null) return Future.value(cached);
    final inFlight = _deviceScopeInFlight;
    if (inFlight != null) return inFlight;

    final future = _loadOrCreateDeviceScope();
    _deviceScopeInFlight = future;
    return future.whenComplete(() {
      if (identical(_deviceScopeInFlight, future)) {
        _deviceScopeInFlight = null;
      }
    });
  }

  static Future<String> _loadOrCreateDeviceScope() async {
    try {
      final saved = await _deviceStorage.read(key: _deviceScopeStorageKey);
      if (saved != null && saved.isNotEmpty) {
        _deviceScope = saved;
        return saved;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('기기 범위 secure storage 읽기 실패: $e');
    }

    final created = Uuid().v4();
    _deviceScope = created;
    try {
      await _deviceStorage.write(key: _deviceScopeStorageKey, value: created);
    } catch (e) {
      // 백업될 수 있는 Hive 값을 fallback으로 사용하지 않습니다. 이 경우에는
      // 현재 앱 실행 동안만 같은 범위를 사용하고, 재실행 시 새로 생성합니다.
      if (kDebugMode) debugPrint('기기 범위 secure storage 저장 실패: $e');
    }
    return created;
  }

  static Future<String> _rememberedEmailsStorageKey() async {
    final scope = await _getDeviceScope();
    return '${_rememberedEmailsKeyPrefix}_$scope';
  }

  /// Firebase 초기화 완료 여부를 Splash와 공유합니다.
  static void completeFirebaseInitialization(bool ready) {
    if (!_firebaseReady.isCompleted) _firebaseReady.complete(ready);
  }

  static Future<bool> waitForFirebaseInitialization({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      return await _firebaseReady.future.timeout(timeout);
    } catch (_) {
      return false;
    }
  }

  /// 웹에서도 Firebase Auth의 로컬 persistence를 명시적으로 사용합니다.
  /// 앱은 Firebase Auth 네이티브 기본 persistence를 그대로 사용합니다.
  static Future<void> configurePersistentAuth() async {
    if (!kIsWeb) return;
    try {
      await _auth.setPersistence(Persistence.LOCAL);
    } catch (e) {
      if (kDebugMode) debugPrint('웹 로그인 persistence 설정 실패: $e');
    }
  }

  // ────────────────────────────────────────────
  // 전화번호 SMS 인증 - 코드 발송
  // ────────────────────────────────────────────
  static Future<Map<String, dynamic>> sendPhoneVerification({
    required String phoneNumber, // E.164 형식: +821012345678
  }) async {
    final completer = Completer<Map<String, dynamic>>();

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // 자동 인증도 인증된 Firebase 사용자를 유지합니다. register()가
        // 동일 UID에 이메일 자격증명을 연결하여 인증 결과를 결속합니다.
        try {
          final signedIn = await _auth.signInWithCredential(credential);
          if (!completer.isCompleted) {
            completer.complete({
              'status': 'auto_verified',
              'phoneNumber': signedIn.user?.phoneNumber ?? '',
            });
          }
        } catch (_) {
          if (!completer.isCompleted) {
            completer.complete({'status': 'error', 'message': '자동 인증에 실패했습니다. 다시 시도해주세요.'});
          }
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          String msg;
          switch (e.code) {
            case 'invalid-phone-number':
              msg = '올바른 전화번호 형식이 아닙니다.';
              break;
            case 'too-many-requests':
              msg = '너무 많은 요청이 발생했습니다. 잠시 후 다시 시도해주세요.';
              break;
            case 'quota-exceeded':
              msg = 'SMS 발송 한도를 초과했습니다. 내일 다시 시도해주세요.';
              break;
            case 'operation-not-allowed':
              msg = '전화번호 인증이 활성화되지 않았습니다. 관리자에게 문의하세요.';
              break;
            default:
              msg = '문자 인증 요청에 실패했습니다. 잠시 후 다시 시도해주세요.';
          }
          completer.complete({'status': 'error', 'message': msg});
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) {
          completer.complete({
            'status': 'code_sent',
            'verificationId': verificationId,
            'resendToken': resendToken,
          });
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (!completer.isCompleted) {
          completer.complete({
            'status': 'timeout',
            'verificationId': verificationId,
          });
        }
      },
    );

    return completer.future;
  }

  // ────────────────────────────────────────────
  // 전화번호 SMS 인증 - OTP 코드 검증
  // ────────────────────────────────────────────
  static Future<Map<String, dynamic>> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      // 소셜 로그인으로 이미 Firebase 사용자가 있으면 새 전화번호 계정을
      // 만들지 않고 같은 UID에 Phone provider를 연결합니다. 일반 회원가입처럼
      // 현재 사용자가 없거나 이미 전화번호 계정인 경우에만 signInWithCredential을 사용합니다.
      final currentUser = _auth.currentUser;
      final result = currentUser != null && currentUser.phoneNumber == null
          ? await currentUser.linkWithCredential(credential)
          : await _auth.signInWithCredential(credential);
      final phoneNumber = result.user?.phoneNumber ?? '';
      if (phoneNumber.isEmpty) {
        return {'status': 'error', 'message': '인증된 전화번호를 확인할 수 없습니다.'};
      }
      return {'status': 'verified', 'phoneNumber': phoneNumber};
    } on FirebaseAuthException catch (e) {
      String msg;
      switch (e.code) {
        case 'invalid-verification-code':
          msg = '인증번호가 올바르지 않습니다. 다시 확인해주세요.';
          break;
        case 'session-expired':
          msg = '인증번호가 만료되었습니다. 다시 발송해주세요.';
          break;
        default:
          msg = '인증번호 확인에 실패했습니다. 다시 시도해주세요.';
      }
      return {'status': 'error', 'message': msg};
    } catch (e) {
      return {'status': 'error', 'message': '인증 중 오류가 발생했습니다.'};
    }
  }

  // 소셜 로그인 최초 가입 완료: 전화번호 인증이 끝난 동일 UID에만 회원 문서를 생성합니다.
  static Future<AuthResult> completeSocialPhoneOnboarding({
    required String name,
    required String email,
    required String phone,
    String photoUrl = '',
    String provider = 'social',
  }) async {
    try {
      final user = _auth.currentUser;
      final verifiedPhone = user?.phoneNumber?.trim() ?? '';
      if (user == null || verifiedPhone.isEmpty) {
        return const AuthResult(
          success: false,
          error: '전화번호 본인확인을 먼저 완료해주세요.',
        );
      }
      if (phone.trim() != verifiedPhone) {
        return const AuthResult(
          success: false,
          error: '인증된 전화번호와 입력한 전화번호가 일치하지 않습니다.',
        );
      }
      final emailKey = email.trim().toLowerCase();
      if (emailKey.isEmpty || name.trim().isEmpty) {
        return const AuthResult(success: false, error: '회원정보가 올바르지 않습니다.');
      }
      final docRef = _db.collection('users').doc(user.uid);
      final existing = await docRef.get();
      if (existing.exists) {
        return const AuthResult(success: false, error: '이미 가입된 계정입니다. 다시 로그인해주세요.');
      }
      await user.updateDisplayName(name.trim());
      await user.getIdToken(true);
      await docRef.set({
        'id': user.uid,
        'name': name.trim(),
        'email': emailKey,
        'phone': verifiedPhone,
        'phoneVerified': true,
        'phoneVerifiedAt': FieldValue.serverTimestamp(),
        'isAdmin': false,
        'grade': 'bronze',
        'points': 0,
        'wishlist': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'loginProvider': provider,
        if (photoUrl.trim().isNotEmpty) 'profileImageUrl': photoUrl.trim(),
      });
      final userModel = UserModel(
        id: user.uid,
        name: name.trim(),
        email: emailKey,
        phone: verifiedPhone,
        profileImageUrl: photoUrl,
        memberTier: 'bronze',
        grade: 'bronze',
        isAdmin: await _hasAdminClaim(),
        createdAt: DateTime.now(),
        loginProvider: provider,
      );
      await _saveSession(user.uid);
      return AuthResult(success: true, user: userModel);
    } on FirebaseException catch (e) {
      if (kDebugMode) debugPrint('소셜 본인확인 온보딩 저장 실패: ${e.code}');
      return const AuthResult(success: false, error: '회원정보 저장에 실패했습니다. 다시 시도해주세요.');
    } catch (e) {
      if (kDebugMode) debugPrint('소셜 본인확인 온보딩 오류: $e');
      return const AuthResult(success: false, error: '본인확인 가입 중 오류가 발생했습니다.');
    }
  }

  // ────────────────────────────────────────────
  // 이메일 중복 확인
  // ────────────────────────────────────────────
  static Future<bool> checkEmailAvailable(String email) async {
    try {
      final emailKey = email.trim().toLowerCase();
      // Firestore에서 이메일 중복 확인 (타임아웃 10초)
      final query = await _db
          .collection('users')
          .where('email', isEqualTo: emailKey)
          .limit(1)
          .get()
          .timeout(const Duration(seconds: 10));
      return query.docs.isEmpty;
    } catch (e) {
      if (kDebugMode) debugPrint('이메일 중복확인 오류: $e');
      // 오류 시 사용 가능으로 처리 (Firebase가 나중에 검증)
      return true;
    }
  }

  // ────────────────────────────────────────────
  // 비밀번호 강도 검증 (서버사이드)
  // ────────────────────────────────────────────
  static String? validatePasswordStrength(String password) {
    if (password.length < 8) return '비밀번호는 8자 이상이어야 합니다.';
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    // 특수문자: 단순하고 웹 호환되는 패턴으로 교체
    final hasSpecial = password
        .split('')
        .any((c) => '!@#\$%^&*()_+-=[]{}|;:,.<>?/`~\\"\'\\\\'.contains(c));
    final score =
        [hasUpper, hasLower, hasDigit, hasSpecial].where((c) => c).length;
    if (score < 2) {
      return '비밀번호는 대문자, 소문자, 숫자, 특수문자 중 2가지 이상을 포함해야 합니다.';
    }
    return null; // 통과
  }

  // ────────────────────────────────────────────
  // 회원가입
  // ────────────────────────────────────────────
  static Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
  }) async {
    // 유효성 검사
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    if (!emailRegex.hasMatch(email.trim())) {
      return const AuthResult(success: false, error: '유효한 이메일 주소를 입력해주세요.');
    }
    if (name.trim().length < 2) {
      return const AuthResult(success: false, error: '이름은 2자 이상 입력해주세요.');
    }
    if (name.trim().length > 20) {
      return const AuthResult(success: false, error: '이름은 20자 이하로 입력해주세요.');
    }
    // 이름 특수문자/숫자/이모지 서버사이드 차단 (한글/영문/공백만 허용)
    if (!RegExp(r'^[가-힣a-zA-Z\s]+$').hasMatch(name.trim())) {
      return const AuthResult(success: false, error: '이름은 한글 또는 영문만 입력 가능합니다.');
    }
    // 연속 공백 차단
    if (name.trim().contains(RegExp(r'\s{2,}'))) {
      return const AuthResult(success: false, error: '이름에 연속 공백을 사용할 수 없습니다.');
    }
    // 전화번호 필수 + 기본 검증
    if (phone.trim().isEmpty) {
      return const AuthResult(success: false, error: '휴대폰 번호는 필수입니다.');
    }
    final phoneDigits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phoneDigits.length < 6 || phoneDigits.length > 15) {
      return const AuthResult(success: false, error: '올바른 전화번호를 입력해주세요.');
    }
    // 강화된 비밀번호 검증 (8자 이상, 복잡도 조건)
    final pwError = validatePasswordStrength(password);
    if (pwError != null) {
      return AuthResult(success: false, error: pwError);
    }

    try {
      final emailKey = email.trim().toLowerCase();
      final currentUser = _auth.currentUser;
      late UserCredential credential;
      final verifiedPhone = currentUser?.phoneNumber?.trim() ?? '';
      if (verifiedPhone.isEmpty) {
        return const AuthResult(
          success: false,
          error: '휴대폰 본인확인을 완료한 뒤 가입할 수 있습니다.',
        );
      }
      if (verifiedPhone.isNotEmpty) {
        // SMS로 인증된 동일 Firebase UID에 이메일 자격증명을 연결합니다.
        final emailCredential = EmailAuthProvider.credential(
          email: emailKey,
          password: password,
        );
        credential = await currentUser!.linkWithCredential(emailCredential);
      }
      // linked provider와 phone_number가 반영된 최신 ID 토큰으로 Firestore
      // 규칙의 hasVerifiedPhone() 검사를 통과하도록 갱신합니다.
      await credential.user!.getIdToken(true);

      final uid = credential.user!.uid;
      // 관리자 권한은 서버가 발급한 Custom Claim으로만 결정합니다.
      const isAdmin = false;

      // Firebase Auth 표시 이름 설정
      await credential.user!.updateDisplayName(name.trim());

      // Firestore에 사용자 문서 저장
      try {
        await _db.collection('users').doc(uid).set({
          'id': uid,
          'name': name.trim(),
          'email': emailKey,
          'phone': verifiedPhone.isNotEmpty ? verifiedPhone : phone.trim(),
          'phoneVerified': verifiedPhone.isNotEmpty,
          'phoneVerifiedAt': verifiedPhone.isNotEmpty ? FieldValue.serverTimestamp() : null,
          'isAdmin': isAdmin,
          'grade': 'bronze',
          'wishlist': <String>[],
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        if (kDebugMode) debugPrint('Firestore 저장 오류 (무시): $e');
        // Firestore 저장 실패해도 Firebase Auth 계정은 생성됨 → 계속 진행
      }

      final benefits = await _claimWelcomeBenefits();
      final user = UserModel(
        id: uid,
        name: name.trim(),
        email: emailKey,
        phone: verifiedPhone.isNotEmpty ? verifiedPhone : phone.trim(),
        isAdmin: isAdmin,
        points: benefits.pointsGranted ? 1000 : 0,
        createdAt: DateTime.now(),
      );

      await _saveSession(uid);
      if (kDebugMode) {
        debugPrint('✅ Firebase 회원 등록 완료: $emailKey (welcomePoints=${benefits.pointsGranted}, welcomeCoupon=${benefits.couponGranted})');
      }
      return AuthResult(
        success: true,
        user: user,
        welcomeBonusGranted: benefits.pointsGranted,
        welcomeCouponGranted: benefits.couponGranted,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _authError(e.code));
    } catch (e) {
      if (kDebugMode) debugPrint('회원가입 오류 상세: $e');
      return const AuthResult(
        success: false,
        error: '회원가입 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.',
      );
    }
  }

  static Future<({bool pointsGranted, bool couponGranted})>
      _claimWelcomeBenefits() async {
    const empty = (pointsGranted: false, couponGranted: false);
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return empty;
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null || idToken.isEmpty) return empty;
      final response = await http.post(
        Uri.parse(
            'https://us-central1-fit-mall.cloudfunctions.net/claimWelcomeBonus'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return empty;
      final payload = jsonDecode(response.body);
      if (payload is! Map || payload['success'] != true) return empty;
      return (
        pointsGranted: payload['pointsGranted'] == true,
        couponGranted: payload['couponGranted'] == true,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('가입 축하 혜택 지급 실패: $e');
      return empty;
    }
  }

  // ────────────────────────────────────────────
  // 로컬 폴백 (Firebase 연결 불가 시 관리자만 허용)
  // 비밀번호는 소스에 저장하지 않고 Firebase Auth에서만 검증
  // ────────────────────────────────────────────
  static AuthResult? _tryLocalLogin(String emailKey, String password) {
    // Firebase 연결 불가 시에도 관리자 계정은 Firebase Auth를 통해 검증
    // 로컬 폴백은 제거 - 보안상 하드코딩 비밀번호 사용 금지
    return null;
  }

  // ────────────────────────────────────────────
  // 로그인
  // ────────────────────────────────────────────
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final emailKey = email.trim().toLowerCase();

    // ① 로컬 계정 먼저 확인 (Firebase 연결 없이도 동작)
    final localResult = _tryLocalLogin(emailKey, password);
    if (localResult != null) {
      if (kDebugMode) debugPrint('✅ 로컬 계정 로그인: $emailKey');
      return localResult;
    }

    // ② Firebase Auth 시도
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: emailKey,
        password: password,
      );

      final uid = credential.user!.uid;
      // 소유자 관리자 계정의 claim이 누락된 경우 서버에서 복구합니다.
      // 관리자 claim 복구는 보조 작업입니다. 이 요청이 지연되거나 실패해도
      // 정상적인 Firebase 이메일 로그인이 화면에서 취소되지 않도록 제한 시간 내에만 기다립니다.
      await _ensureOwnerAdminClaim(credential.user!).timeout(
        const Duration(seconds: 8),
        onTimeout: () {},
      );
      // 관리자 custom claim은 로그인 직후 강제 갱신해야 새로 부여된 권한이 반영됩니다.
      final user = await _loadUser(uid, emailKey, forceRefreshAdminClaim: true);
      if (user == null) {
        return const AuthResult(success: false, error: '사용자 정보를 불러올 수 없습니다.');
      }

      await _saveSession(uid);
      return AuthResult(success: true, user: user);
    } on FirebaseAuthException catch (e) {
      // Firebase 오류는 상세 메시지 반환
      return AuthResult(success: false, error: _authError(e.code));
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 로그인 예외: $e');
      return const AuthResult(
          success: false, error: '로그인 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.');
    }
  }

  static Future<void> _ensureOwnerAdminClaim(User firebaseUser) async {
    try {
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null || idToken.isEmpty) return;
      final response = await http.post(
        Uri.parse('https://us-central1-fit-mall.cloudfunctions.net/ensureOwnerAdminClaim'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({}),
      );
      if (response.statusCode == 200) {
        await firebaseUser.getIdToken(true);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('관리자 권한 확인 생략: $e');
    }
  }

  // ────────────────────────────────────────────
  // 자동 로그인 (세션 복구)
  // ────────────────────────────────────────────
  static Future<AuthResult> restoreSession() {
    final inFlight = _restoreSessionInFlight;
    if (inFlight != null) return inFlight;

    final future = _restoreSessionInternal();
    _restoreSessionInFlight = future;
    return future.whenComplete(() {
      if (identical(_restoreSessionInFlight, future)) {
        _restoreSessionInFlight = null;
      }
    });
  }

  static Future<AuthResult> _restoreSessionInternal() async {
    try {
      // 새로고침 직후 Firebase Auth가 IndexedDB 세션을 복원할 때까지 기다립니다.
      User? firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        try {
          firebaseUser = await _auth.authStateChanges().first.timeout(
            const Duration(seconds: 5),
            onTimeout: () => null,
          );
        } catch (_) {}
      }
      // Firebase Auth 복원 결과와 로컬 세션을 함께 기준으로 버전을 확인합니다.
      if (!await _validateSessionVersion(firebaseUser: firebaseUser)) {
        return const AuthResult(success: false);
      }
      if (firebaseUser != null) {
        final user =
            await _loadUser(firebaseUser.uid, firebaseUser.email ?? '', forceRefreshAdminClaim: true);
        if (user != null) {
          await _saveSession(firebaseUser.uid);
          return AuthResult(success: true, user: user);
        }
      }

      // 레거시 Hive 세션은 Firebase Auth가 동일 UID로 복원된 경우에만 신뢰합니다.
      final sessionBox = await _getSessionBox();
      final savedUid = sessionBox.get('currentUid') as String?;
      final activeUid = _auth.currentUser?.uid;
      if (savedUid != null && activeUid != null && savedUid == activeUid) {
        final email = sessionBox.get('currentEmail') as String? ?? '';
        final user = await _loadUser(savedUid, email, forceRefreshAdminClaim: true);
        if (user != null) {
          await _saveSession(savedUid);
          return AuthResult(success: true, user: user);
        }
      } else if (savedUid != null && activeUid == null) {
        await sessionBox.deleteAll(['currentUid', 'currentEmail']);
      }

      return const AuthResult(success: false);
    } catch (_) {
      return const AuthResult(success: false);
    }
  }

  // ────────────────────────────────────────────
  // 로그아웃
  // ────────────────────────────────────────────
  static Future<void> logout() async {
    try {
      await _auth.signOut();
    } finally {
      final sessionBox = await _getSessionBox();
      await sessionBox.deleteAll(['currentUid', 'currentEmail', 'user']);
    }
  }

  // ────────────────────────────────────────────
  // 회원정보 업데이트
  // ────────────────────────────────────────────
  static Future<bool> updateProfile({
    required String email,
    String? name,
    String? phone,
    String? newPassword,
    String? currentPassword,
  }) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return false;

      final updates = <String, dynamic>{};
      if (name != null && name.trim().isNotEmpty) {
        updates['name'] = name.trim();
        await firebaseUser.updateDisplayName(name.trim());
      }
      if (phone != null && phone.trim().isNotEmpty) {
        // 전화번호 변경은 기존 본인확인 결과를 무효화할 수 있으므로,
        // NICE/Firebase 재인증 플로우 없이 일반 프로필 수정으로 변경하지 못하게 합니다.
        final verifiedPhone = firebaseUser.phoneNumber?.trim() ?? '';
        if (verifiedPhone.isEmpty || phone.trim() != verifiedPhone) return false;
      }

      if (newPassword != null && newPassword.isNotEmpty) {
        if (currentPassword == null || currentPassword.isEmpty) return false;
        if (validatePasswordStrength(newPassword) != null) return false;
        // 재인증 후 비밀번호 변경
        final cred = EmailAuthProvider.credential(
          email: firebaseUser.email!,
          password: currentPassword,
        );
        await firebaseUser.reauthenticateWithCredential(cred);
        await firebaseUser.updatePassword(newPassword);
      }

      if (updates.isNotEmpty) {
        await _db.collection('users').doc(firebaseUser.uid).update(updates);
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // ────────────────────────────────────────────
  // 비밀번호 재설정 이메일 발송
  // ────────────────────────────────────────────
  static Future<AuthResult> resetPassword({required String email}) async {
    final emailKey = email.trim().toLowerCase();
    if (!RegExp(r'^[\w.\-+]+@[\w.\-]+\.\w{2,}$').hasMatch(emailKey)) {
      return const AuthResult(success: false, error: '유효한 이메일 주소를 입력해주세요.');
    }
    try {
      await _auth.sendPasswordResetEmail(email: emailKey);
      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      // 등록 여부를 구분해 계정 존재 여부를 노출하지 않습니다.
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
        return const AuthResult(success: true);
      }
      return const AuthResult(
        success: false,
        error: '비밀번호 재설정 요청을 처리할 수 없습니다. 잠시 후 다시 시도해 주세요.',
      );
    } catch (_) {
      return const AuthResult(
        success: false,
        error: '비밀번호 재설정 요청을 처리할 수 없습니다. 잠시 후 다시 시도해 주세요.',
      );
    }
  }

  // ────────────────────────────────────────────
  // 소셜 로그인 (카카오/구글 — 향후 확장)
  // ────────────────────────────────────────────
  static Future<AuthResult> socialLogin({
    required String provider,
    required String name,
    required String email,
  }) async {
    if (provider == 'google') return signInWithGoogle();
    if (provider == 'kakao') return signInWithKakao();
    if (provider == 'naver') return signInWithNaver();
    return const AuthResult(success: false, error: '지원하지 않는 로그인 방식입니다.');
  }

  // ────────────────────────────────────────────
  // 로그인 상태 유지 (Remember Me)
  // ────────────────────────────────────────────
  /// 현재 기기에서 저장된 아이디 목록을 최근 사용 순서로 반환합니다.
  static Future<List<String>> getRememberedEmails() async {
    final sessionBox = await _getSessionBox();
    final deviceKey = await _rememberedEmailsStorageKey();
    final stored = sessionBox.get(deviceKey);
    final emails = stored is List
        ? stored
            .whereType<String>()
            .map((e) => e.trim().toLowerCase())
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
        : <String>[];

    // 이전 버전의 전역 저장값은 다른 기기로 복원될 수 있으므로 사용하지 않고 삭제합니다.
    await sessionBox.delete(_legacyRememberedEmailsKey);
    await sessionBox.delete(_legacyRememberMeEmailKey);
    return emails;
  }

  static Future<void> saveRememberMe(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return;
    final emails = await getRememberedEmails();
    emails.remove(normalized);
    emails.insert(0, normalized);
    // 무제한으로 계정 식별자가 쌓이지 않도록 최근 10개만 보관합니다.
    final sessionBox = await _getSessionBox();
    await sessionBox.put(
      await _rememberedEmailsStorageKey(),
      emails.take(10).toList(),
    );
  }

  static Future<String?> getRememberMeEmail() async {
    final emails = await getRememberedEmails();
    return emails.isEmpty ? null : emails.first;
  }

  static Future<void> clearRememberMe([String? email]) async {
    final sessionBox = await _getSessionBox();
    final deviceKey = await _rememberedEmailsStorageKey();
    if (email == null || email.trim().isEmpty) {
      await sessionBox.delete(deviceKey);
      await sessionBox.delete(_legacyRememberedEmailsKey);
      await sessionBox.delete(_legacyRememberMeEmailKey);
      return;
    }
    final normalized = email.trim().toLowerCase();
    final emails = await getRememberedEmails();
    emails.remove(normalized);
    if (emails.isEmpty) {
      await sessionBox.delete(deviceKey);
    } else {
      await sessionBox.put(deviceKey, emails);
    }
  }

  // ────────────────────────────────────────────
  // 내부 유틸리티
  // ────────────────────────────────────────────

  /// 현재 Firebase ID 토큰의 관리자 Custom Claim만 확인합니다.
  static Future<bool> _hasAdminClaim({bool forceRefresh = false}) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return false;
      final token = await firebaseUser.getIdTokenResult(forceRefresh);
      return token.claims?['admin'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Firestore에서 사용자 정보 읽기
  static Future<UserModel?> _loadUser(
    String uid,
    String email, {
    bool forceRefreshAdminClaim = false,
  }) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        final emailKey = (data['email'] as String?) ?? email;
        final isAdmin = await _hasAdminClaim(forceRefresh: forceRefreshAdminClaim);
        return UserModel(
          id: uid,
          name: (data['name'] as String?) ?? '회원',
          email: emailKey,
          phone: (data['phone'] as String?) ?? '',
          profileImageUrl: (data['profileImageUrl'] as String?) ?? '',
          isAdmin: isAdmin,
          memberTier: (data['memberTier'] as String?) ??
              (data['grade'] as String?) ??
              'bronze',
          wishlist: List<String>.from(data['wishlist'] ?? []),
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          loginProvider: (data['loginProvider'] as String?) ?? 'email',
          cashReceiptNum: data['cashReceiptNum'] as String?,
          orderNotificationsEnabled:
              data['orderNotificationsEnabled'] as bool? ?? true,
          marketingNotificationsEnabled:
              data['marketingNotificationsEnabled'] as bool? ?? false,
          addresses: (data['addresses'] as List? ?? [])
              .map((a) =>
                  AddressModel.fromJson(Map<String, dynamic>.from(a as Map)))
              .toList(),
        );
      }

      // Firestore 문서가 없으면 기본 생성
      final isAdmin = await _hasAdminClaim();
      final displayName = _auth.currentUser?.displayName ?? '회원';
      final user = UserModel(
        id: uid,
        name: displayName,
        email: email,
        phone: '',
        isAdmin: isAdmin,
        createdAt: DateTime.now(),
        loginProvider: 'email',
      );
      try {
        await _db.collection('users').doc(uid).set({
          'id': uid,
          'name': displayName,
          'email': email,
          'phone': '',
          'isAdmin': isAdmin,
          'grade': 'bronze',
          'wishlist': <String>[],
          'loginProvider': 'email',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        // 인증은 성공했지만 사용자 문서 생성이 일시적으로 실패해도
        // 기본 사용자로 로그인 흐름을 계속 진행합니다.
        if (kDebugMode) debugPrint('사용자 문서 생성 생략: $e');
      }
      return user;
    } catch (e) {
      if (kDebugMode) debugPrint('_loadUser error: $e');
      // Firebase Auth 인증 자체가 성공한 경우 Firestore 조회 실패만으로
      // 로그인 화면으로 되돌리지 않도록 최소 프로필을 반환합니다.
      final current = _auth.currentUser;
      if (current?.uid != uid) return null;
      return UserModel(
        id: uid,
        name: current?.displayName ?? '회원',
        email: current?.email ?? email,
        phone: current?.phoneNumber ?? '',
        isAdmin: await _hasAdminClaim(),
        createdAt: DateTime.now(),
        loginProvider: 'email',
      );
    }
  }

  static const _fallbackAppVersion = '1.0.5';

  static Future<String> _currentAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      // CI 빌드 번호는 같은 앱 버전에서도 매번 바뀔 수 있으므로
      // 세션 초기화 기준에는 사용자에게 배포하는 앱 버전만 사용합니다.
      final version = info.version;
      return version.isEmpty ? _fallbackAppVersion.split('+').first : version;
    } catch (e) {
      if (kDebugMode) debugPrint('앱 버전 확인 실패, fallback 사용: $e');
      return _fallbackAppVersion;
    }
  }

  /// 앱/웹 업데이트마다 기존 로그인 세션을 한 번만 폐기합니다.
  static Future<bool> _validateSessionVersion({User? firebaseUser}) async {
    final sessionBox = await _getSessionBox();
    final currentVersion = await _currentAppVersion();
    final savedVersion = sessionBox.get(_sessionVersionKey) as String?;
    final hasActiveSession = firebaseUser != null ||
        _auth.currentUser != null ||
        sessionBox.get('currentUid') != null ||
        sessionBox.get('user') is Map;

    if (hasActiveSession &&
        (savedVersion == null || savedVersion != currentVersion)) {
      try {
        await _auth.signOut();
      } catch (e) {
        if (kDebugMode) debugPrint('업데이트 후 Firebase 세션 정리 실패: $e');
      }
      await signOutGoogle();
      await signOutKakao();
      await sessionBox.deleteAll(['currentUid', 'currentEmail', 'user']);
      await sessionBox.put(_sessionVersionKey, currentVersion);
      return false;
    }

    if (savedVersion != currentVersion) {
      await sessionBox.put(_sessionVersionKey, currentVersion);
    }
    return true;
  }

  static Future<void> _saveSession(String uid) async {
    try {
      final sessionBox = await _getSessionBox();
      final email = _auth.currentUser?.email ?? '';
      await sessionBox.put('currentUid', uid);
      await sessionBox.put('currentEmail', email);
      await sessionBox.put(_sessionVersionKey, await _currentAppVersion());
    } catch (e) {
      if (kDebugMode) debugPrint('세션 저장 오류 (무시): $e');
      // 세션 저장 실패해도 회원가입은 성공으로 처리
    }
  }

  /// Firebase Auth 에러 코드 → 한국어 메시지
  static String _authError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return '이미 사용 중인 이메일입니다.';
      case 'invalid-email':
        return '유효하지 않은 이메일 형식입니다.';
      case 'weak-password':
        return '비밀번호는 6자 이상이어야 합니다.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return '이메일 또는 비밀번호가 올바르지 않습니다.';
      case 'user-disabled':
        return '비활성화된 계정입니다. 고객센터에 문의하세요.';
      case 'too-many-requests':
        return '잠시 후 다시 시도해주세요.';
      case 'network-request-failed':
        return '네트워크 연결을 확인해주세요.';
      default:
        return '오류가 발생했습니다. 다시 시도해주세요.';
    }
  }

  // 레거시 호환용 (기존 코드에서 참조하는 경우 대비)
  static Future<void> updatePoints(String email, int points) async {
    // Firebase 기반에서는 포인트 시스템 제거됨
  }

  static Future<void> updateAddresses(
      String email, List<dynamic> addresses) async {
    try {
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) return;
      await _db.collection('users').doc(firebaseUser.uid).update({
        'addresses': addresses.map((a) => (a as dynamic).toJson()).toList(),
      });
    } catch (_) {}
  }

  // ────────────────────────────────────────────
  // 관리자용: 전체 회원 목록 조회 (Firestore users)
  // ────────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final snapshot = await _db
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['uid'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 회원 목록 조회 실패: $e');
      // orderBy 실패 시 단순 조회로 폴백
      try {
        final snapshot = await _db.collection('users').get();
        final list = snapshot.docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['uid'] = doc.id;
          return data;
        }).toList();
        list.sort((a, b) {
          final aDate =
              (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
          final bDate =
              (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });
        return list;
      } catch (e2) {
        if (kDebugMode) debugPrint('⚠️ 회원 목록 폴백 실패: $e2');
        return [];
      }
    }
  }

  // 실시간 회원 목록 스트림
  static Stream<List<Map<String, dynamic>>> watchAllUsers() {
    return _db.collection('users').snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['uid'] = doc.id;
        return data;
      }).toList();
      list.sort((a, b) {
        final aDate =
            (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final bDate =
            (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // 회원 등급 변경
  static Future<void> updateUserGrade(String uid, String grade) async {
    try {
      await _db.collection('users').doc(uid).update({'memberTier': grade});
      if (kDebugMode) debugPrint('✅ 회원 등급 변경: $uid → $grade');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 등급 변경 실패: $e');
    }
  }

  // 회원 차단/해제
  static Future<void> updateUserBlocked(String uid, bool blocked) async {
    try {
      await _db.collection('users').doc(uid).update({'isBlocked': blocked});
      if (kDebugMode) debugPrint('✅ 회원 차단 변경: $uid → $blocked');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 차단 변경 실패: $e');
    }
  }

  // 회원 삭제 (Firestore 문서만 삭제, Auth는 Admin SDK 필요)
  static Future<void> deleteUserDocument(String uid) async {
    try {
      await _db.collection('users').doc(uid).delete();
      if (kDebugMode) debugPrint('🗑️ 회원 문서 삭제: $uid');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 회원 삭제 실패: $e');
    }
  }

  // 회원 메모 저장
  static Future<void> updateUserMemo(String uid, String memo) async {
    try {
      await _db.collection('users').doc(uid).update({'adminMemo': memo});
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 메모 저장 실패: $e');
    }
  }

  // ── 구글 소셜 로그인 ──────────────────────────────
  static final _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // 웹 클라이언트 ID (Firebase Console → Authentication → Google → 웹 SDK 구성)
    clientId:
        '187081765755-hbucij2qnqaqsgvah5lnqdofb7ma7d1s.apps.googleusercontent.com',
  );

  static Future<AuthResult> signInWithGoogle() async {
    try {
      GoogleSignInAccount? googleUser;
      if (kIsWeb) {
        googleUser = await _googleSignIn.signInSilently() ??
            await _googleSignIn.signIn();
      } else {
        googleUser = await _googleSignIn.signIn();
      }
      if (googleUser == null) {
        return const AuthResult(success: false, error: '구글 로그인이 취소되었습니다.');
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null)
        return const AuthResult(success: false, error: '로그인 실패');

      final emailKey = (user.email ?? '').toLowerCase();
      final isAdmin = await _hasAdminClaim();

      // Firestore에 사용자 문서 생성/업데이트 (assertion 에러 시 폴백)
      Map<String, dynamic>? firestoreData;
      try {
        await Future.delayed(const Duration(milliseconds: 300));
        final docRef = _db.collection('users').doc(user.uid);
        final doc = await docRef.get();
        if (!doc.exists) {
          await docRef.set({
            'id': user.uid,
            'name': user.displayName ?? googleUser.displayName ?? '회원',
            'email': user.email ?? '',
            'phone': '',
            'phoneVerified': false,
            'profileImageUrl': user.photoURL ?? '',
            'grade': 'bronze',
            'isAdmin': isAdmin,
            'points': 0,
            'coupons': [],
            'wishlist': [],
            'createdAt': FieldValue.serverTimestamp(),
            'loginProvider': 'google',
          });
          firestoreData = {
            'name': user.displayName ?? '회원',
            'email': user.email ?? '',
            'phone': '',
            'phoneVerified': false,
            'profileImageUrl': user.photoURL ?? '',
            'grade': 'bronze',
            'isAdmin': isAdmin,
            'points': 0,
            'wishlist': [],
          };
        } else {
          docRef.update({
            'lastLoginAt': FieldValue.serverTimestamp(),
            'loginProvider': 'google',
          }).catchError((_) {});
          firestoreData = doc.data();
        }
        try {
          final fresh = await _db.collection('users').doc(user.uid).get();
          if (fresh.data() != null) firestoreData = fresh.data();
        } catch (_) {}
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ 구글 Firestore 오류 (무시하고 계속): $e');
        firestoreData ??= {};
      }

      final data = firestoreData ?? {};
      final tier =
          data['memberTier'] as String? ?? data['grade'] as String? ?? 'bronze';
      final userModel = UserModel(
        id: user.uid,
        name: data['name'] as String? ?? user.displayName ?? '회원',
        email: data['email'] as String? ?? user.email ?? '',
        phone: data['phone'] as String? ?? '',
        profileImageUrl:
            data['profileImageUrl'] as String? ?? user.photoURL ?? '',
        memberTier: tier,
        grade: tier,
        isAdmin: isAdmin,
        wishlist: List<String>.from(data['wishlist'] as List? ?? []),
        createdAt: DateTime.now(),
        loginProvider: 'google',
        cashReceiptNum: data['cashReceiptNum'] as String?,
        orderNotificationsEnabled:
            data['orderNotificationsEnabled'] as bool? ?? true,
        marketingNotificationsEnabled:
            data['marketingNotificationsEnabled'] as bool? ?? false,
        addresses: (data['addresses'] as List? ?? [])
            .map((a) =>
                AddressModel.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList(),
      );
      // 세션 저장
      try {
        final box = await _getSessionBox();
        await box.put('user', {
          'id': userModel.id,
          'name': userModel.name,
          'email': userModel.email,
          'phone': userModel.phone,
          'profileImageUrl': userModel.profileImageUrl,
          'grade': userModel.memberTier,
          'isAdmin': userModel.isAdmin,
          'wishlist': userModel.wishlist,
          'loginProvider': userModel.loginProvider,
          if (userModel.cashReceiptNum?.isNotEmpty == true)
            'cashReceiptNum': userModel.cashReceiptNum,
          'orderNotificationsEnabled': userModel.orderNotificationsEnabled,
          'marketingNotificationsEnabled': userModel.marketingNotificationsEnabled,
        });
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ 구글 세션 저장 실패 (무시): $e');
      }
      await _saveSession(user.uid);
      return AuthResult(success: true, user: userModel);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 구글 로그인 실패: $e');
      return AuthResult(success: false, error: '구글 로그인 실패: $e');
    }
  }

  static Future<void> signOutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 구글 로그아웃 실패: $e');
    }
  }

  // ── 카카오 소셜 로그인 ──────────────────────────────────
  // 카카오 앱 키는 main.dart KakaoSdk.init()에서 초기화
  // Flutter Web: 카카오 JS SDK → OAuthToken 발급
  // Android/iOS: 카카오톡 앱 또는 카카오계정 웹뷰 로그인
  static Future<AuthResult> signInWithKakao() async {
    // ── Step 1: 카카오 SDK 토큰 발급 ──────────────────────────
    kakao.OAuthToken token;
    try {
      if (kIsWeb) {
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
      } else {
        final isInstalled = await kakao.isKakaoTalkInstalled();
        token = isInstalled
            ? await kakao.UserApi.instance.loginWithKakaoTalk()
            : await kakao.UserApi.instance.loginWithKakaoAccount();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 카카오 토큰 발급 실패: $e');
      return AuthResult(success: false, error: '카카오 로그인에 실패했습니다. 다시 시도해주세요.');
    }

    if (kDebugMode) debugPrint('✅ 카카오 토큰 발급 성공');

    // ── Step 2: 카카오 사용자 정보 조회 ──────────────────────
    late String kakaoId;
    late String email;
    late String name;
    late String photoUrl;
    try {
      final kakaoUser = await kakao.UserApi.instance.me();
      final kakaoAccount = kakaoUser.kakaoAccount;
      final profile = kakaoAccount?.profile;
      kakaoId = kakaoUser.id.toString();
      email = kakaoAccount?.email ?? '$kakaoId@kakao.com';
      name = profile?.nickname ?? '카카오 사용자';
      photoUrl = profile?.profileImageUrl ?? '';
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 카카오 사용자 정보 조회 실패: $e');
      return AuthResult(success: false, error: '카카오 사용자 정보를 가져올 수 없습니다.');
    }

    // ── Step 3: 서버 검증 후 Firebase Custom Token 로그인 ─────────
    // Kakao 계정을 일반 password provider와 구분할 수 있도록 access token을
    // 서버에서 검증하고 provider:kakao Custom Claim을 포함한 토큰을 발급받습니다.
    UserCredential userCred;
    try {
      final response = await http.post(
        Uri.parse('https://us-central1-fit-mall.cloudfunctions.net/exchangeKakaoToken'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'accessToken': token.accessToken}),
      );
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AuthResult(
          success: false,
          error: payload['error'] as String? ?? '카카오 계정 인증에 실패했습니다.',
        );
      }
      final customToken = payload['customToken'] as String?;
      if (customToken == null || customToken.isEmpty) {
        return const AuthResult(success: false, error: '카카오 인증 토큰을 받지 못했습니다.');
      }
      userCred = await _auth.signInWithCustomToken(customToken);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 카카오 서버 인증 실패: $e');
      return const AuthResult(
          success: false, error: '카카오 로그인 중 오류가 발생했습니다. 다시 시도해주세요.');
    }

    final user = userCred.user;
    if (user == null) {
      return const AuthResult(success: false, error: '카카오 로그인 실패: 사용자 정보 없음');
    }

    // 사용자 이름 업데이트 (비동기, 실패해도 무시)
    if (user.displayName == null || user.displayName!.isEmpty) {
      user.updateDisplayName(name).catchError((_) {});
    }

    final isAdmin = await _hasAdminClaim();

    // ── Step 4: Firestore 사용자 문서 생성/업데이트 ──────────
    // Firestore assertion 에러(Auth 토큰 갱신 경쟁 상태)가 발생해도
    // Firebase Auth 로그인은 이미 성공했으므로 로컬 데이터로 진행합니다.
    Map<String, dynamic>? firestoreData;
    try {
      // 짧은 딜레이: Auth 상태 변경 이벤트가 Firestore 스트림에 전파될 시간 확보
      await Future.delayed(const Duration(milliseconds: 300));
      final docRef = _db.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'id': user.uid,
          'name': name,
          'email': email,
          'phone': '',
          'phoneVerified': false,
          'profileImageUrl': photoUrl,
          'grade': 'bronze',
          'isAdmin': isAdmin,
          'points': 0,
          'coupons': [],
          'wishlist': [],
          'createdAt': FieldValue.serverTimestamp(),
          'loginProvider': 'kakao',
          'kakaoId': kakaoId,
        });
        firestoreData = {
          'name': name,
          'email': email,
          'phone': '',
          'phoneVerified': false,
          'profileImageUrl': photoUrl,
          'grade': 'bronze',
          'isAdmin': isAdmin,
          'points': 0,
          'wishlist': [],
        };
      } else {
        // 업데이트 (실패해도 계속)
        docRef.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'loginProvider': 'kakao',
          'kakaoId': kakaoId,
          if (photoUrl.isNotEmpty) 'profileImageUrl': photoUrl,
        }).catchError((_) {});
        firestoreData = doc.data();
      }
      // 최신 데이터 다시 읽기 (실패 시 기존 데이터 사용)
      try {
        final fresh = await _db.collection('users').doc(user.uid).get();
        if (fresh.data() != null) firestoreData = fresh.data();
      } catch (_) {}
    } catch (e) {
      // Firestore assertion / 네트워크 오류 → 로컬 데이터로 폴백
      if (kDebugMode) debugPrint('⚠️ Firestore 쓰기 오류 (무시하고 계속): $e');
      firestoreData ??= {};
    }

    final data = firestoreData ?? {};
    final tier =
        data['memberTier'] as String? ?? data['grade'] as String? ?? 'bronze';
    final userModel = UserModel(
      id: user.uid,
      name: data['name'] as String? ?? name,
      email: data['email'] as String? ?? email,
      phone: data['phone'] as String? ?? '',
      profileImageUrl: data['profileImageUrl'] as String? ?? photoUrl,
      memberTier: tier,
      grade: tier,
      isAdmin: isAdmin,
      wishlist: List<String>.from(data['wishlist'] as List? ?? []),
      createdAt: DateTime.now(),
      loginProvider: 'kakao',
      cashReceiptNum: data['cashReceiptNum'] as String?,
      orderNotificationsEnabled:
          data['orderNotificationsEnabled'] as bool? ?? true,
      marketingNotificationsEnabled:
          data['marketingNotificationsEnabled'] as bool? ?? false,
      addresses: (data['addresses'] as List? ?? [])
          .map(
              (a) => AddressModel.fromJson(Map<String, dynamic>.from(a as Map)))
          .toList(),
    );

    // ── Step 5: 세션 저장 ────────────────────────────────────
    try {
      final box = await _getSessionBox();
      await box.put('user', {
        'id': userModel.id,
        'name': userModel.name,
        'email': userModel.email,
        'phone': userModel.phone,
        'profileImageUrl': userModel.profileImageUrl,
        'grade': userModel.memberTier,
        'isAdmin': userModel.isAdmin,
        'wishlist': userModel.wishlist,
        'loginProvider': userModel.loginProvider,
        if (userModel.cashReceiptNum?.isNotEmpty == true)
          'cashReceiptNum': userModel.cashReceiptNum,
        'orderNotificationsEnabled': userModel.orderNotificationsEnabled,
        'marketingNotificationsEnabled': userModel.marketingNotificationsEnabled,
      });
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 세션 저장 실패 (무시): $e');
    }
    await _saveSession(user.uid);

    if (kDebugMode) debugPrint('✅ 카카오 로그인 완료: ${userModel.name}');
    return AuthResult(success: true, user: userModel);
  }

  static Future<void> signOutKakao() async {
    try {
      await kakao.UserApi.instance.logout();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 카카오 로그아웃 실패: $e');
    }
  }

  // ────────────────────────────────────────────
  // 네이버 소셜 로그인
  // ────────────────────────────────────────────
  static Future<AuthResult> signInWithNaver() async {
    try {
      if (kIsWeb) {
        // ── 웹: JS 팝업 OAuth 방식 ──
        return await _signInWithNaverWeb();
      }

      // ── 앱: 외부 브라우저 + HTTPS 콜백 + twofitmall 딥링크 ──
      final startResponse = await http.post(
        Uri.parse(
            'https://us-central1-fit-mall.cloudfunctions.net/startNaverOAuth'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'redirectUri': _naverRedirectUri}),
      );
      final startPayload =
          jsonDecode(startResponse.body) as Map<String, dynamic>;
      if (startResponse.statusCode < 200 || startResponse.statusCode >= 300) {
        return AuthResult(
            success: false,
            error: startPayload['error'] as String? ?? '네이버 로그인을 시작할 수 없습니다.');
      }
      final authorizeUrl = startPayload['authorizeUrl'] as String?;
      if (authorizeUrl == null || authorizeUrl.isEmpty) {
        return const AuthResult(success: false, error: '네이버 로그인 주소를 받지 못했습니다.');
      }
      if (!await launchUrl(Uri.parse(authorizeUrl),
          mode: LaunchMode.externalApplication)) {
        return const AuthResult(success: false, error: '네이버 로그인 화면을 열 수 없습니다.');
      }
      final info = await _waitForNaverMobileCode();
      return await _exchangeNaverCodeForFirebase(info);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 네이버 로그인 실패: $e');
      return const AuthResult(success: false, error: '네이버 로그인에 실패했습니다. 다시 시도해주세요.');
    }
  }

  static Future<AuthResult> _exchangeNaverCodeForFirebase(
      Map<String, String> info) async {
    final response = await http.post(
      Uri.parse(
          'https://us-central1-fit-mall.cloudfunctions.net/exchangeNaverCode'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(info),
    );
    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return AuthResult(
          success: false,
          error: payload['error'] as String? ?? '네이버 로그인에 실패했습니다.');
    }
    final customToken = payload['customToken'] as String?;
    if (customToken == null || customToken.isEmpty) {
      return const AuthResult(
          success: false, error: 'Firebase 인증 토큰을 받지 못했습니다.');
    }
    final credential = await _auth.signInWithCustomToken(customToken);
    final firebaseUser = credential.user;
    if (firebaseUser == null) {
      return const AuthResult(
          success: false, error: 'Firebase 사용자 정보를 받지 못했습니다.');
    }
    final doc = await _db.collection('users').doc(firebaseUser.uid).get();
    if (!doc.exists) {
      return AuthResult(
        success: false,
        requiresPhoneVerification: true,
        pendingName: firebaseUser.displayName ?? '네이버 사용자',
        pendingEmail: firebaseUser.email ?? '',
        pendingPhotoUrl: firebaseUser.photoURL ?? '',
        pendingProvider: 'naver',
        error: '전화번호 본인확인을 완료해주세요.',
      );
    }
    final data = doc.data() ?? <String, dynamic>{};
    final tier =
        data['memberTier'] as String? ?? data['grade'] as String? ?? 'bronze';
    final userModel = UserModel(
      id: firebaseUser.uid,
      name: data['name'] as String? ?? firebaseUser.displayName ?? '네이버 사용자',
      email: data['email'] as String? ?? firebaseUser.email ?? '',
      phone: data['phone'] as String? ?? '',
      profileImageUrl: data['profileImageUrl'] as String? ?? '',
      memberTier: tier,
      grade: tier,
      isAdmin: await _hasAdminClaim(),
      wishlist: List<String>.from(data['wishlist'] as List? ?? const []),
      createdAt: DateTime.now(),
      loginProvider: 'naver',
      cashReceiptNum: data['cashReceiptNum'] as String?,
      orderNotificationsEnabled:
          data['orderNotificationsEnabled'] as bool? ?? true,
      marketingNotificationsEnabled:
          data['marketingNotificationsEnabled'] as bool? ?? false,
      addresses: (data['addresses'] as List? ?? const [])
          .map(
              (a) => AddressModel.fromJson(Map<String, dynamic>.from(a as Map)))
          .toList(),
    );
    final box = await _getSessionBox();
    await box.put('user', {
      'id': userModel.id,
      'name': userModel.name,
      'email': userModel.email,
      'phone': userModel.phone,
      'profileImageUrl': userModel.profileImageUrl,
      'grade': userModel.memberTier,
      'isAdmin': userModel.isAdmin,
      'wishlist': userModel.wishlist,
      'loginProvider': userModel.loginProvider,
      if (userModel.cashReceiptNum?.isNotEmpty == true)
        'cashReceiptNum': userModel.cashReceiptNum,
      'orderNotificationsEnabled': userModel.orderNotificationsEnabled,
      'marketingNotificationsEnabled': userModel.marketingNotificationsEnabled,
    });
    await _saveSession(firebaseUser.uid);
    return AuthResult(success: true, user: userModel);
  }

  /// 웹 전용 네이버 OAuth: authorization code를 서버에서 교환하고 Custom Token으로 로그인
  static Future<AuthResult> _signInWithNaverWeb() async {
    try {
      final info = await naverWeb.callNaverOAuth();
      if (info == null) {
        return const AuthResult(success: false, error: '네이버 로그인이 취소되었습니다.');
      }
      final code = info['code'] ?? '';
      final state = info['state'] ?? '';
      final redirectUri = info['redirectUri'] ?? '';
      if (code.isEmpty || state.isEmpty || redirectUri.isEmpty) {
        return const AuthResult(success: false, error: '네이버 인증 코드가 없습니다.');
      }

      final response = await http.post(
        Uri.parse(
            'https://us-central1-fit-mall.cloudfunctions.net/exchangeNaverCode'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'code': code,
          'state': state,
          'redirectUri': redirectUri,
        }),
      );
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return AuthResult(
            success: false,
            error: payload['error'] as String? ?? '네이버 로그인에 실패했습니다.');
      }
      final customToken = payload['customToken'] as String?;
      if (customToken == null || customToken.isEmpty) {
        return const AuthResult(
            success: false, error: 'Firebase 인증 토큰을 받지 못했습니다.');
      }

      final credential = await _auth.signInWithCustomToken(customToken);
      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        return const AuthResult(
            success: false, error: 'Firebase 사용자 정보를 받지 못했습니다.');
      }
    final doc = await _db.collection('users').doc(firebaseUser.uid).get();
    if (!doc.exists) {
      return AuthResult(
        success: false,
        requiresPhoneVerification: true,
        pendingName: firebaseUser.displayName ?? '네이버 사용자',
        pendingEmail: firebaseUser.email ?? '',
        pendingPhotoUrl: firebaseUser.photoURL ?? '',
        pendingProvider: 'naver',
        error: '전화번호 본인확인을 완료해주세요.',
      );
    }
    final data = doc.data() ?? <String, dynamic>{};
    final tier =
          data['memberTier'] as String? ?? data['grade'] as String? ?? 'bronze';
      final userModel = UserModel(
        id: firebaseUser.uid,
        name: data['name'] as String? ?? firebaseUser.displayName ?? '네이버 사용자',
        email: data['email'] as String? ?? firebaseUser.email ?? '',
        phone: data['phone'] as String? ?? '',
        profileImageUrl: data['profileImageUrl'] as String? ?? '',
        memberTier: tier,
        grade: tier,
        isAdmin: await _hasAdminClaim(),
        wishlist: List<String>.from(data['wishlist'] as List? ?? const []),
        createdAt: DateTime.now(),
        loginProvider: 'naver',
        cashReceiptNum: data['cashReceiptNum'] as String?,
        orderNotificationsEnabled:
            data['orderNotificationsEnabled'] as bool? ?? true,
        marketingNotificationsEnabled:
            data['marketingNotificationsEnabled'] as bool? ?? false,
        addresses: (data['addresses'] as List? ?? const [])
            .map((a) =>
                AddressModel.fromJson(Map<String, dynamic>.from(a as Map)))
            .toList(),
      );
      final box = await _getSessionBox();
      await box.put('user', {
        'id': userModel.id,
        'name': userModel.name,
        'email': userModel.email,
        'phone': userModel.phone,
        'profileImageUrl': userModel.profileImageUrl,
        'grade': userModel.memberTier,
        'isAdmin': userModel.isAdmin,
        'wishlist': userModel.wishlist,
        'loginProvider': userModel.loginProvider,
        if (userModel.cashReceiptNum?.isNotEmpty == true)
          'cashReceiptNum': userModel.cashReceiptNum,
        'orderNotificationsEnabled': userModel.orderNotificationsEnabled,
        'marketingNotificationsEnabled': userModel.marketingNotificationsEnabled,
      });
      await _saveSession(firebaseUser.uid);
      return AuthResult(success: true, user: userModel);
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 네이버 웹 로그인 실패: $e');
      return const AuthResult(
          success: false, error: '네이버 로그인에 실패했습니다. 다시 시도해주세요.');
    }
  }

  static Future<void> signOutNaver() async {
    try {
      await _auth.signOut();
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ 네이버 로그아웃 실패: $e');
    }
  }
}
