# 전화번호 중복 방지 테스트 시나리오

## 1. 정규화 단위 테스트

`AuthService.normalizePhoneNumber`는 Firebase 초기화 없이 실행할 수 있으므로 다음 테스트를 `test/phone_number_normalization_test.dart`로 복사해 실행할 수 있습니다.

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:twofit_mall/services/auth_service.dart';

void main() {
  group('전화번호 정규화', () {
    test('한국 국내 표기를 E.164 형식으로 통일한다', () {
      expect(
        AuthService.normalizePhoneNumber('010-1234-5678'),
        '+821012345678',
      );
      expect(
        AuthService.normalizePhoneNumber('010 1234 5678'),
        '+821012345678',
      );
      expect(
        AuthService.normalizePhoneNumber('+82 10 1234 5678'),
        '+821012345678',
      );
    });

    test('같은 번호의 여러 입력 형식이 동일한 값이 된다', () {
      final values = [
        '010-1234-5678',
        '01012345678',
        '821012345678',
        '+821012345678',
      ].map(AuthService.normalizePhoneNumber).toSet();

      expect(values, {'+821012345678'});
    });
  });
}
```

실행 명령은 다음과 같습니다.

```bash
flutter test test/phone_number_normalization_test.dart
```

## 2. Firebase Emulator 통합 테스트 형태

아래 코드는 실제 SMS를 보내지 않고, 두 사용자에게 같은 `phoneIndex` 문서를 점유시키는 상황을 검증하는 예시입니다. 프로젝트의 Firebase Emulator 설정에 맞춰 초기화 코드를 연결한 뒤 사용할 수 있습니다.

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

Future<bool> claimPhoneIndexForTest({
  required FirebaseFirestore db,
  required String phone,
  required String uid,
}) async {
  final phoneId = phone.replaceAll('+', 'p');
  final ref = db.collection('phoneIndex').doc(phoneId);

  return db.runTransaction<bool>((tx) async {
    final snapshot = await tx.get(ref);
    if (snapshot.exists && snapshot.data()?['uid'] != uid) {
      return false;
    }
    tx.set(ref, {
      'uid': uid,
      'phone': phone,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return true;
  });
}

void main() {
  late FirebaseFirestore db;

  setUp(() {
    db = FirebaseFirestore.instance;
  });

  test('첫 번째 계정은 전화번호를 점유할 수 있다', () async {
    final claimed = await claimPhoneIndexForTest(
      db: db,
      phone: '+821012345678',
      uid: 'user-a',
    );

    expect(claimed, isTrue);
  });

  test('두 번째 계정은 이미 점유된 전화번호를 사용할 수 없다', () async {
    await claimPhoneIndexForTest(
      db: db,
      phone: '+821012345678',
      uid: 'user-a',
    );

    final claimed = await claimPhoneIndexForTest(
      db: db,
      phone: '+821012345678',
      uid: 'user-b',
    );

    expect(claimed, isFalse);
  });

  test('같은 계정의 재시도는 허용된다', () async {
    await claimPhoneIndexForTest(
      db: db,
      phone: '+821012345678',
      uid: 'user-a',
    );

    final claimedAgain = await claimPhoneIndexForTest(
      db: db,
      phone: '+821012345678',
      uid: 'user-a',
    );

    expect(claimedAgain, isTrue);
  });
}
```

## 3. 실제 앱 테스트 시나리오

### 정상 등록

```text
계정 A 로그인
→ 연락처에 010-1234-5678 입력
→ 인증번호 받기
→ 올바른 6자리 인증번호 입력
→ 인증번호 확인
→ 프로필 저장
→ 성공 메시지 확인
```

예상 결과는 `phoneIndex/p821012345678` 문서에 계정 A의 UID가 기록되고, 사용자 문서의 `phone` 값은 `+821012345678`로 저장되는 것입니다.

### 동일 번호 중복 등록

```text
계정 A에서 +821012345678 인증 완료
→ 로그아웃
→ 계정 B 로그인
→ 010 1234 5678 입력
→ 인증번호 받기
→ 인증번호 확인
```

예상 결과는 인증 완료 후 저장이 거부되고 다음 메시지가 표시되는 것입니다.

```text
이미 다른 회원이 사용 중인 전화번호입니다.
```

### 표기 형식만 다른 중복 등록

```text
계정 A: 010-1234-5678
계정 B: +82 10 1234 5678
```

두 값은 동일한 `+821012345678`로 정규화되므로 계정 B의 등록은 거부되어야 합니다.

### 번호 변경과 이전 번호 재사용

```text
계정 A: 010-1234-5678 → 010-2222-3333으로 변경
→ 계정 B에서 010-1234-5678 등록 시도
```

계정 A의 새 번호 인증이 성공하고 저장까지 완료되면, 이전 번호 인덱스가 정리되어 계정 B는 SMS 인증 후 등록할 수 있어야 합니다.

### 잘못된 인증번호

```text
올바른 전화번호 입력
→ 인증번호 받기
→ 000000 입력
→ 인증번호 확인
```

전화번호 인덱스가 생성되면 안 되며, 인증번호 오류 메시지와 재입력 UI가 유지되어야 합니다.

### 인증번호 만료·재발송

```text
인증번호 받기
→ 제한 시간 경과
→ 새 인증번호 받기
→ 새 인증번호 입력
```

이전 인증번호로는 실패하고 새 인증번호로만 성공해야 합니다. 성공 전에는 `phoneIndex`가 생성되면 안 됩니다.

## 4. 현재 코드 감사에서 확인된 추가 보완 후보

| 우선순위 | 항목 | 확인 내용 | 권장 조치 |
|---|---|---|---|
| P1 | Auth와 `phoneIndex` 원자성 | Firebase Auth 전화번호 연결 후 Firestore 인덱스 점유가 실패하면 두 저장소가 잠시 어긋날 수 있음 | 서버 Callable Function에서 인증된 UID·전화번호·중복 인덱스를 한 흐름으로 처리하거나 실패 시 보상 정리 추가 |
| P1 | 기존 데이터 마이그레이션 | 기존 회원은 `phoneIndex` 문서가 없을 수 있음 | 관리자용 1회 마이그레이션으로 인증 완료 회원의 인덱스 생성, 충돌 로그 작성 |
| P1 | 회원가입 경로 | `verifyPhoneOtp`가 기존 전화번호 계정으로 로그인하는 흐름과 새 회원가입 흐름을 함께 처리함 | 신규 가입·기존 계정 로그인·소셜 온보딩을 명확히 분리하고 기존 계정 자동 로그인 여부를 사용자에게 안내 |
| P2 | 정규화 함수 중복 | 프로필 화면의 `_normalizePhone`과 AuthService의 `normalizePhoneNumber`가 별도로 존재함 | UI에서도 `AuthService.normalizePhoneNumber`를 사용해 규칙을 한 곳으로 통합 |
| P2 | 오류 메시지 일관성 | SMS 발송 실패·인증번호 오류·중복 번호 오류가 경로별로 다르게 표시될 가능성 | 공통 오류 코드와 다국어 메시지 매핑을 추가 |
| P2 | 전화번호 개인정보 노출 | `phoneIndex`는 소유자만 읽도록 되어 있지만 관리자 화면·로그에 전화번호가 남을 수 있음 | 관리자 로그에는 마스킹 번호만 표시하고 원문 검색을 제한 |
| P2 | 웹 자동 인증 | 웹은 Android 자동 SMS 인증과 동작이 다를 수 있음 | 웹에서 `codeSent`·`verificationFailed`·재발송을 별도 브라우저 테스트 |
| P3 | 분석 경고 | 기존 CI에 사용하지 않는 변수와 `dart:html` deprecation 경고가 남아 있음 | 기능 안정화 후 파일별로 정리하고 `package:web`·`dart:js_interop` 전환을 별도 작업으로 진행 |
| P3 | 배포 검증 | Play 업로드 성공과 실제 테스트 계정의 Play Store 노출은 별개임 | 내부 테스트 계정에서 설치·업데이트·최신 상태 배너를 확인 |

## 5. 테스트 통과 기준

전화번호 중복 방지 기능은 다음 조건을 모두 만족해야 통과로 판단합니다.

```text
정규화 형식 통일
+ 동일 번호의 표기 변형 차단
+ 다른 UID의 중복 점유 차단
+ 같은 UID 재시도 허용
+ 잘못된 OTP에서 인덱스 미생성
+ 번호 변경 시 이전 인덱스 정리
+ Firebase Auth와 users 문서의 전화번호 일치
```

현재 자동 배포는 성공했지만, 실제 SMS를 사용하는 테스트와 기존 회원 데이터의 `phoneIndex` 마이그레이션 검증은 별도로 필요합니다.

## 6. 권장 수정 순서

먼저 기존 회원의 `phoneIndex` 마이그레이션과 Auth·Firestore 간 보상 정리를 보완하는 것이 좋습니다. 그 다음 프로필 화면의 중복 정규화 함수를 AuthService 하나로 통합하고, 회원가입·소셜 온보딩·프로필 변경의 전화번호 흐름을 분리해 테스트하면 앱과 웹의 동작 차이를 줄일 수 있습니다.
