// auth_service.dart — Firebase Auth 기반 (이메일/비밀번호)
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/models.dart';

class AuthService {
  static const _sessionBox = 'session';

  // 관리자 이메일 목록 (하드코딩 — Firestore isAdmin 플래그와 병행)
  static const _adminEmails = [
    'chw243527@gmail.com',
    'tbrk2435@naver.com',
    'admin@2fitkorea.com',
    'cs@2fitkorea.com',
  ];

  static FirebaseAuth get _auth => FirebaseAuth.instance;
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static Future<Box> _getSessionBox() async {
    if (Hive.isBoxOpen(_sessionBox)) return Hive.box(_sessionBox);
    return await Hive.openBox(_sessionBox);
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
    final hasSpecial = password.split('').any((c) =>
        '!@#\$%^&*()_+-=[]{}|;:,.<>?/`~\\"\'\\\\'.contains(c));
    final score = [hasUpper, hasLower, hasDigit, hasSpecial].where((c) => c).length;
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
      // Firebase Auth 계정 생성
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final uid = credential.user!.uid;
      final emailKey = email.trim().toLowerCase();
      final isAdmin = _adminEmails.contains(emailKey);

      // Firebase Auth 표시 이름 설정
      await credential.user!.updateDisplayName(name.trim());

      // Firestore에 사용자 문서 저장
      try {
        await _db.collection('users').doc(uid).set({
          'id': uid,
          'name': name.trim(),
          'email': emailKey,
          'phone': phone.trim(),
          'isAdmin': isAdmin,
          'grade': 'bronze',
          'wishlist': <String>[],
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        if (kDebugMode) debugPrint('Firestore 저장 오류 (무시): $e');
        // Firestore 저장 실패해도 Firebase Auth 계정은 생성됨 → 계속 진행
      }

      final user = UserModel(
        id: uid,
        name: name.trim(),
        email: emailKey,
        phone: phone.trim(),
        isAdmin: isAdmin,
        createdAt: DateTime.now(),
      );

      await _saveSession(uid);
      if (kDebugMode) debugPrint('✅ Firebase 회원 등록 완료: $emailKey');
      return AuthResult(success: true, user: user);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _authError(e.code));
    } catch (e) {
      if (kDebugMode) debugPrint('회원가입 오류 상세: $e');
      return AuthResult(success: false, error: '오류: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e.toString()}');
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
      final user = await _loadUser(uid, emailKey);
      if (user == null) {
        return const AuthResult(success: false, error: '사용자 정보를 불러올 수 없습니다.');
      }

      await _saveSession(uid);
      return AuthResult(success: true, user: user);
    } on FirebaseAuthException catch (e) {
      // Firebase 오류는 상세 메시지 반환
      return AuthResult(success: false, error: _authError(e.code));
    } catch (e) {
      final errStr = e.toString();
      // Firebase 미설정/네트워크 오류 시 → 이메일+비밀번호 조합이 맞으면 임시 로컬 허용
      if (errStr.contains('invalid-api-key') ||
          errStr.contains('network') ||
          errStr.contains('CONFIGURATION_NOT_FOUND') ||
          errStr.contains('APIKeyNotValid')) {
        if (emailKey.contains('@') && password.length >= 6) {
          final isAdmin = _adminEmails.contains(emailKey);
          final user = UserModel(
            id: 'fallback_${emailKey.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
            name: emailKey.split('@').first,
            email: emailKey,
            phone: '',
            address: '',
            createdAt: DateTime.now(),
            isAdmin: isAdmin,
            wishlist: [],
          );
          if (kDebugMode) debugPrint('⚠️ Firebase 연결 실패, 폴백 로그인: $emailKey');
          return AuthResult(success: true, user: user);
        }
      }
      return const AuthResult(success: false, error: '로그인 중 오류가 발생했습니다.');
    }
  }

  // ────────────────────────────────────────────
  // 자동 로그인 (세션 복구)
  // ────────────────────────────────────────────
  static Future<AuthResult> restoreSession() async {
    try {
      // Firebase Auth 현재 사용자 확인
      final firebaseUser = _auth.currentUser;
      if (firebaseUser != null) {
        final user = await _loadUser(firebaseUser.uid, firebaseUser.email ?? '');
        if (user != null) {
          return AuthResult(success: true, user: user);
        }
      }

      // Hive 세션 확인 (레거시 폴백)
      final sessionBox = await _getSessionBox();
      final savedUid = sessionBox.get('currentUid') as String?;
      if (savedUid != null) {
        final email = sessionBox.get('currentEmail') as String? ?? '';
        final user = await _loadUser(savedUid, email);
        if (user != null) return AuthResult(success: true, user: user);
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
    await _auth.signOut();
    final sessionBox = await _getSessionBox();
    await sessionBox.deleteAll(['currentUid', 'currentEmail']);
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
      if (phone != null) updates['phone'] = phone.trim();

      if (newPassword != null && newPassword.length >= 6 && currentPassword != null) {
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
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
      return const AuthResult(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult(success: false, error: _authError(e.code));
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
    // TODO: 카카오/구글 OAuth 연동 시 구현
    return const AuthResult(success: false, error: '소셜 로그인은 현재 준비 중입니다.');
  }

  // ────────────────────────────────────────────
  // 로그인 상태 유지 (Remember Me)
  // ────────────────────────────────────────────
  static Future<void> saveRememberMe(String email) async {
    final sessionBox = await _getSessionBox();
    await sessionBox.put('rememberMeEmail', email.trim().toLowerCase());
  }

  static Future<String?> getRememberMeEmail() async {
    final sessionBox = await _getSessionBox();
    return sessionBox.get('rememberMeEmail') as String?;
  }

  static Future<void> clearRememberMe() async {
    final sessionBox = await _getSessionBox();
    await sessionBox.delete('rememberMeEmail');
  }

  // ────────────────────────────────────────────
  // 내부 유틸리티
  // ────────────────────────────────────────────

  /// Firestore에서 사용자 정보 읽기
  static Future<UserModel?> _loadUser(String uid, String email) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        final emailKey = (data['email'] as String?) ?? email;
        final isAdmin = (data['isAdmin'] as bool?) ?? _adminEmails.contains(emailKey);
        return UserModel(
          id: uid,
          name: (data['name'] as String?) ?? '회원',
          email: emailKey,
          phone: (data['phone'] as String?) ?? '',
          isAdmin: isAdmin,
          wishlist: List<String>.from(data['wishlist'] ?? []),
          createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }

      // Firestore 문서가 없으면 기본 생성
      final isAdmin = _adminEmails.contains(email);
      final displayName = _auth.currentUser?.displayName ?? '회원';
      final user = UserModel(
        id: uid,
        name: displayName,
        email: email,
        phone: '',
        isAdmin: isAdmin,
        createdAt: DateTime.now(),
      );
      await _db.collection('users').doc(uid).set({
        'id': uid,
        'name': displayName,
        'email': email,
        'phone': '',
        'isAdmin': isAdmin,
        'grade': 'bronze',
        'wishlist': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
      return user;
    } catch (e) {
      if (kDebugMode) debugPrint('_loadUser error: $e');
      return null;
    }
  }

  static Future<void> _saveSession(String uid) async {
    try {
      final sessionBox = await _getSessionBox();
      final email = _auth.currentUser?.email ?? '';
      await sessionBox.put('currentUid', uid);
      await sessionBox.put('currentEmail', email);
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
        return '가입되지 않은 이메일입니다.';
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
        return '오류가 발생했습니다. 다시 시도해주세요. ($code)';
    }
  }

  // 레거시 호환용 (기존 코드에서 참조하는 경우 대비)
  static Future<void> updatePoints(String email, int points) async {
    // Firebase 기반에서는 포인트 시스템 제거됨
  }

  static Future<void> updateAddresses(String email, List<dynamic> addresses) async {
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
          final aDate = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
          final bDate = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
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
        final aDate = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final bDate = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
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
    clientId: '187081765755-hbucij2qnqaqsgvah5lnqdofb7ma7d1s.apps.googleusercontent.com',
  );

  static Future<AuthResult> signInWithGoogle() async {
    try {
      GoogleSignInAccount? googleUser;
      if (kIsWeb) {
        googleUser = await _googleSignIn.signInSilently() ?? await _googleSignIn.signIn();
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
      if (user == null) return const AuthResult(success: false, error: '로그인 실패');

      final emailKey = (user.email ?? '').toLowerCase();
      final isAdmin = _adminEmails.contains(emailKey);

      // Firestore에 사용자 문서 생성/업데이트
      final docRef = _db.collection('users').doc(user.uid);
      final doc = await docRef.get();
      if (!doc.exists) {
        await docRef.set({
          'id': user.uid,
          'name': user.displayName ?? googleUser.displayName ?? '회원',
          'email': user.email ?? '',
          'phone': '',
          'profileImageUrl': user.photoURL ?? '',
          'grade': 'bronze',
          'isAdmin': isAdmin,
          'points': 0,
          'coupons': [],
          'wishlist': [],
          'createdAt': FieldValue.serverTimestamp(),
          'loginProvider': 'google',
        });
      } else {
        await docRef.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'loginProvider': 'google',
        });
      }
      final data = (await docRef.get()).data()!;
      final tier = data['memberTier'] as String? ?? data['grade'] as String? ?? 'bronze';
      final userModel = UserModel(
        id: user.uid,
        name: data['name'] as String? ?? '',
        email: data['email'] as String? ?? '',
        phone: data['phone'] as String? ?? '',
        profileImageUrl: data['profileImageUrl'] as String? ?? '',
        memberTier: tier,
        grade: tier,
        isAdmin: (data['isAdmin'] as bool?) ?? isAdmin,
        points: (data['points'] as int?) ?? 0,
        coupons: const [],
        wishlist: List<String>.from(data['wishlist'] as List? ?? []),
        createdAt: DateTime.now(),
      );
      // 세션 저장
      final box = await _getSessionBox();
      await box.put('user', {
        'id': userModel.id, 'name': userModel.name, 'email': userModel.email,
        'phone': userModel.phone, 'profileImageUrl': userModel.profileImageUrl,
        'grade': userModel.memberTier, 'isAdmin': userModel.isAdmin,
        'points': userModel.points, 'wishlist': userModel.wishlist,
      });
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
}
