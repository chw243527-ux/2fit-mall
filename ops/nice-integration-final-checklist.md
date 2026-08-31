# NICE 본인인증 연동 최종 체크리스트

## 적용 범위와 현재 회원 정책

현재 2FIT MALL의 회원 정책은 다음과 같이 구분한다.

| 회원 유형 | NICE 본인인증 정책 |
|---|---|
| 일반 이메일·비밀번호 회원가입 | 전화번호 본인인증 필수 |
| Google·Kakao·Naver 소셜 회원가입 | 가입 시 NICE 본인인증 불필요 |
| 주문·결제·성인·민감 회원정보 변경 등 지정 기능 | 운영 정책에 따라 NICE 본인인증 요구 가능 |

NICE 연동은 화면에서 이름이나 전화번호를 입력받는 기능이 아니라, **NICE가 반환한 인증 결과를 서버에서 검증하고 그 결과를 현재 Firebase UID와 결속하는 기능**으로 구현해야 한다. CI·DI 원문과 NICE 암호화 응답은 클라이언트 화면, URL, 일반 Firestore 문서, 로그에 노출하지 않는다.

## 1. 계약·NICE 발급정보 확인

- [ ] NICE 계약서와 최신 개발가이드의 적용 버전을 보관한다.
- [ ] 운영·개발 환경별 사이트 코드와 서비스 코드가 구분되어 있는지 확인한다.
- [ ] 운영·개발 환경별 암호화 키, 복호화 키, 라이선스 키, 해시 키의 명칭과 보관 위치를 확정한다.
- [ ] 연동 방식(API, 팝업, 리다이렉트, 모바일 SDK, 웹뷰 등)을 NICE와 확정한다.
- [ ] 성공·실패·취소 콜백 URL을 개발·스테이징·운영별로 등록한다.
- [ ] 허용 도메인, 포트, TLS 조건, IP allowlist가 필요한지 확인한다.
- [ ] NICE가 제공하는 거래번호·요청번호·nonce·세션 식별자의 생성·검증·유효시간·일회성 규칙을 확인한다.
- [ ] NICE 테스트 키와 운영 키를 분리하고, 테스트 종료 후 테스트 키를 폐기 또는 비활성화한다.
- [ ] NICE가 반환하는 이름·생년월일·성별·휴대전화·CI·DI·국적 등의 필수·선택 필드를 계약 목적별로 정리한다.
- [ ] 보관해야 하는 값과 즉시 폐기해야 하는 값을 NICE 및 개인정보 처리방침 기준으로 확정한다.

## 2. 클라이언트 구현

### 2.1 인증 시작

- [ ] 클라이언트는 서버의 ‘NICE 인증 시작’ API만 호출하고 NICE 암호화 키를 직접 사용하지 않는다.
- [ ] 서버가 발급한 인증 세션 ID 또는 일회성 state만 클라이언트에 전달한다.
- [ ] state·nonce·거래번호를 URL에 넣더라도 개인정보·CI·DI·암호화 결과를 포함하지 않는다.
- [ ] 사용자가 인증 시작 버튼을 여러 번 눌러도 동일 요청이 중복 생성되지 않도록 진행 상태와 rate limit을 적용한다.
- [ ] 팝업 차단, 취소, 닫기, 뒤로가기, 네트워크 오류, 인증 시간 초과를 모두 실패 상태로 처리한다.
- [ ] 인증 성공 화면에서 CI·DI·암호화 문자열·거래번호·내부 Firebase UID를 표시하지 않는다.
- [ ] 모바일 앱·웹·웹뷰에서 콜백 도메인과 redirect URI를 allowlist로 제한한다.

### 2.2 결과 수신과 화면 처리

- [ ] 클라이언트는 NICE 콜백의 결과를 성공으로 신뢰하지 않고 서버 검증 API를 호출한다.
- [ ] 클라이언트가 `success`, `verified`, `phoneVerified`, `ci`, `di`, `name` 값을 수정해도 서버 결과가 바뀌지 않는다.
- [ ] 성공 후 화면 전환은 서버의 검증 결과와 현재 Firebase Auth UID 결속이 완료된 뒤에만 수행한다.
- [ ] 실패·취소·시간 초과 후 기존 성공 상태, 로컬 캐시, sessionStorage, localStorage를 삭제한다.
- [ ] 브라우저 뒤로가기 또는 새로고침으로 이전 NICE 성공 결과를 재사용할 수 없다.
- [ ] 인증 결과와 CI·DI를 query string, fragment, analytics event, crash report에 전달하지 않는다.
- [ ] 개발자 도구 Network·Console·Application 패널에서 개인정보와 암호화 결과가 노출되지 않는지 확인한다.

## 3. 서버 구현

### 3.1 인증 시작 API

- [ ] 로그인된 사용자의 Firebase ID token을 검증하고 UID를 서버 세션에 결속한다.
- [ ] 로그인 전 가입 흐름이라면 서버가 별도 임시 가입 세션을 생성하고, 소셜 계정 식별자 또는 이메일과 결속한다.
- [ ] state·nonce·거래번호는 서버의 암호학적 난수로 생성한다.
- [ ] 인증 세션에는 최소한 `sessionId`, Firebase UID 또는 가입 식별자, 목적, 생성시각, 만료시각, 사용 여부를 저장한다.
- [ ] 인증 목적을 `signup`, `phone_change`, `checkout`, `adult_verification`처럼 구분해 다른 목적의 결과가 재사용되지 않도록 한다.
- [ ] 세션 만료시간을 짧게 설정하고 성공·실패·취소 처리 후 즉시 consumed 처리한다.
- [ ] 서버는 허용된 origin·redirect URI·HTTP method·content type만 받는다.
- [ ] 요청 본문 크기, 문자열 길이, 호출 빈도, IP·UID별 rate limit을 적용한다.

### 3.2 NICE 결과 검증 API

- [ ] 서버가 NICE 응답의 암호화·서명·무결성·거래번호를 최신 NICE 개발가이드 방식으로 검증한다.
- [ ] 복호화·검증 실패, 필수 필드 누락, 만료, 이미 사용된 거래번호는 모두 실패로 처리한다.
- [ ] NICE에서 받은 결과의 이름·생년월일·휴대전화 등과 현재 가입 또는 변경 요청의 입력값을 서버에서 비교한다.
- [ ] 클라이언트가 전달한 이름·전화번호보다 NICE에서 검증한 값을 우선한다.
- [ ] 동일인 검증이 필요한 경우 CI·DI·거래번호·Firebase UID 또는 임시 가입 세션을 서버에서 함께 대조한다.
- [ ] 여러 본인확인 절차가 있는 경우 각 결과가 동일인인지 교차검증한다.
- [ ] 실패 결과를 성공으로 변환하는 fallback, 예외 처리, timeout 기본값이 없는지 코드 리뷰한다.
- [ ] 응답에는 필요한 최소 상태와 마스킹된 정보만 반환하고 CI·DI·복호화 원문을 반환하지 않는다.

### 3.3 Firebase UID 결속

- [ ] 검증 성공 결과를 현재 Firebase UID 또는 서버가 생성한 임시 가입 세션에 결속한다.
- [ ] 일반 이메일 회원가입은 NICE 또는 지정된 전화번호 인증이 완료되지 않으면 `users` 문서 생성이 거부된다.
- [ ] 소셜 회원가입은 가입 정책상 NICE 인증 없이 허용하되, 소셜 인증 토큰과 Firebase UID의 연결을 유지한다.
- [ ] NICE 인증이 필요한 주문·결제·회원정보 변경 요청은 인증 세션의 목적과 현재 UID가 일치해야 한다.
- [ ] 다른 UID가 만든 인증 세션 ID를 사용하면 거부한다.
- [ ] 본인확인 완료 여부는 클라이언트 플래그가 아니라 서버가 검증한 결과와 Firebase Custom Claim 또는 서버 전용 상태로 결정한다.
- [ ] `isAdmin`, `phoneVerified`, `phone`, `ci`, `di`, `points`, `role` 등의 민감 필드는 일반 클라이언트가 생성·수정하지 못하게 한다.
- [ ] Firestore Rules와 서버 Functions가 같은 정책을 적용하는지 확인한다.

## 4. CI·DI 및 개인정보 저장 정책

- [ ] CI·DI 원문을 일반 Firestore `users` 문서에 저장하지 않는다.
- [ ] 불가피하게 보관해야 하면 암호화·접근통제·보유기간·삭제정책을 별도로 승인받는다.
- [ ] 로그, APM, error tracking, analytics, 이메일, 푸시 데이터에 CI·DI와 NICE 원문이 포함되지 않는다.
- [ ] 전화번호·이름·생년월일은 목적에 필요한 최소값만 보관한다.
- [ ] 인증 완료 시각, 인증 목적, NICE 거래 식별자, 결과 상태의 보관 필요성을 검토한다.
- [ ] 인증 세션과 임시 데이터에 TTL 삭제 작업을 둔다.
- [ ] 회원 탈퇴, 개인정보 삭제, 보유기간 만료 시 NICE 관련 데이터가 함께 삭제·비식별화되는지 검증한다.
- [ ] 개인정보처리방침과 회원가입 동의서에 NICE 위탁·수집항목·이용목적·보유기간을 반영한다.
- [ ] 운영자와 고객센터가 CI·DI 원문을 조회할 수 없도록 관리자 화면과 export 기능을 제한한다.

## 5. Firebase Authentication·Firestore·Storage

- [ ] Firebase Console에서 Email/Password, Phone, Google, Kakao, Naver 공급자 정책을 실제 운영 정책과 일치시킨다.
- [ ] `2fit-mall.co.kr`과 필요한 callback 도메인만 Authorized domains에 등록한다.
- [ ] 일반 이메일 가입은 전화번호 인증 없이 Firestore 사용자 문서를 생성할 수 없는지 확인한다.
- [ ] Google·Kakao·Naver 소셜 가입은 전화번호 없이 허용하되 `phoneVerified`, `phone`, `isAdmin`, `points`를 클라이언트가 조작할 수 없는지 확인한다.
- [ ] Firebase Custom Claim을 발급하는 서버만 소셜 provider claim과 관리자 claim을 설정할 수 있다.
- [ ] 관리자 권한 판단에 사용자 문서의 `isAdmin` 값을 사용하지 않고 Auth Custom Claim만 사용한다.
- [ ] Firestore Rules Emulator에서 허용·거부 테스트를 실행한다.
- [ ] Storage 업로드 파일의 소유권·MIME type·크기·경로를 검증한다.
- [ ] App Check 적용 여부를 검토하고 enforcement 전환 전에 실패율을 모니터링한다.
- [ ] Firebase Rules와 Functions를 운영 프로젝트에 배포한 뒤 배포 버전과 Git commit SHA를 기록한다.

## 6. 쿠키·세션·키 관리

- [ ] NICE 세션 쿠키를 사용하는 경우 `Secure`, `HttpOnly`, `SameSite=Lax` 또는 `Strict`를 적용한다.
- [ ] 세션 쿠키와 state·nonce의 만료시간을 짧게 설정한다.
- [ ] CI·DI·NICE 복호화 결과를 쿠키, localStorage, sessionStorage, IndexedDB에 저장하지 않는다.
- [ ] NICE 키와 서버 서비스 계정 JSON을 Flutter Web 번들, APK, GitHub, Firebase Hosting 정적 파일에 넣지 않는다.
- [ ] 운영 키는 Secret Manager 또는 배포 플랫폼의 서버 전용 Secret으로 주입한다.
- [ ] 테스트·운영 Secret을 분리하고 키 교체 절차를 문서화한다.
- [ ] CI 로그에서 Secret mask가 작동하는지 확인한다.
- [ ] 키가 노출됐을 때 즉시 폐기·재발급·영향범위 조사 절차를 마련한다.

## 7. 보안 테스트 시나리오

| 테스트 | 기대 결과 |
|---|---|
| NICE 인증 성공 응답의 이름·전화번호를 클라이언트에서 변조 | 서버가 원래 검증값과 불일치를 감지하고 거부 |
| CI·DI 또는 암호화 응답 일부 삭제 | 실패 처리 |
| 거래번호 재사용 | 두 번째 요청 거부 |
| 만료된 state·nonce 사용 | 거부 |
| 다른 Firebase UID의 인증 세션 사용 | 거부 |
| 실패·취소 응답을 성공으로 변경 | 거부 |
| URL에 직접 `verified=true` 전달 | 아무 효과 없음 |
| 일반 이메일 회원가입에서 본인인증 생략 | Firestore 문서 생성 거부 |
| 소셜 회원가입에서 전화번호 미입력 | 정책에 따라 허용 |
| 소셜 회원이 `phoneVerified=true` 주입 | Firestore Rules 거부 |
| 다른 회원의 NICE 인증 결과 사용 | 거부 |
| 관리자 권한 없는 사용자의 NICE 원문 조회 | 거부 |
| 이전 세션 ID로 새 계정 가입 | 거부 |
| 팝업 종료·뒤로가기·새로고침 후 재개 | 이전 성공 결과 재사용 불가 |
| 서버 timeout·NICE 장애 | 성공으로 처리하지 않고 안전한 실패 |

## 8. 운영·배포 전 최종 확인

- [ ] 개발·스테이징·운영의 NICE 사이트 코드와 callback URL이 서로 섞이지 않는다.
- [ ] 최신 Functions, Firestore Rules, Storage Rules, Flutter Web·Android 빌드가 같은 Git commit에서 생성된다.
- [ ] Firebase Functions 배포가 성공했고 Kakao·Naver·NICE 관련 endpoint가 운영 도메인에서 응답한다.
- [ ] 운영 HTTPS, HSTS, CORS, CSP 또는 필요한 보안 헤더를 확인한다.
- [ ] 운영 도메인에서 일반가입·소셜가입·NICE 인증 필요 기능을 각각 실계정 또는 승인된 테스트 계정으로 시험한다.
- [ ] 인증 성공·실패·취소·재사용·변조 테스트 결과를 마스킹된 증적으로 보관한다.
- [ ] 모니터링 알람에 인증 실패율, timeout, 중복 거래번호, 검증 실패율을 등록한다.
- [ ] NICE 장애 시 고객 안내 문구와 재시도 정책을 준비한다.
- [ ] 계약 제출용으로 화면 캡처, 테스트 결과, 보안 규칙 commit, 배포 로그, 개인정보 처리방침 반영본을 준비한다.

## 9. Go / No-Go 기준

다음 조건을 모두 충족해야 NICE 연동을 운영에 개시한다.

| 기준 | Go 조건 |
|---|---|
| 서버 검증 | NICE 암호화·무결성·거래번호·세션·동일인 검증이 서버에서 성공 |
| UID 결속 | 인증 결과가 현재 Firebase UID 또는 일회성 가입 세션에 결속 |
| 재사용 방지 | 거래번호·state·nonce·세션이 1회 사용 후 폐기 |
| 변조 방지 | 클라이언트의 이름·전화번호·CI·DI·성공 플래그 변조가 모두 거부 |
| 일반가입 | 본인인증 없는 회원 문서 생성이 거부 |
| 소셜가입 | 정책상 본인인증 없이 가입되며 민감 필드 변조는 거부 |
| 키 관리 | NICE 키가 클라이언트·GitHub·로그에 없고 서버 Secret으로만 존재 |
| 운영 배포 | Functions·Rules·클라이언트가 동일 승인 commit으로 배포 |
| 개인정보 | 저장·보유·삭제·접근통제와 개인정보처리방침이 일치 |
| 장애 처리 | 실패·취소·timeout이 성공으로 전환되지 않음 |

다음 중 하나라도 발생하면 **No-Go**다. NICE 원문이나 CI·DI가 브라우저·URL·로그에 노출되는 경우, 클라이언트 입력만으로 인증 성공이 되는 경우, 거래번호를 재사용할 수 있는 경우, 다른 Firebase UID가 인증 결과를 사용할 수 있는 경우, 일반회원이 본인인증 없이 가입되는 경우, 운영 키가 웹 번들에 포함되는 경우, Firebase Rules 또는 Functions 배포가 확인되지 않는 경우다.

## 현재 저장소 기준의 선행 작업

현재 저장소는 일반 이메일 가입의 전화번호 인증 필수와 소셜 가입의 전화번호 인증 선택 정책을 분리한 상태다. NICE 실제 연동 전에는 이 정책 위에 **NICE 시작 API, 서버 검증 API, 일회성 세션 저장소, UID 결속, NICE 키 Secret 주입, 거래번호 재사용 방지**를 추가해야 한다. NICE 계약 후 발급되는 최신 개발가이드의 실제 필드명·암호화 알고리즘·콜백 형식은 문서에 맞춰 확정해야 하며, 개발가이드가 제공되기 전에는 해당 세부 구현을 임의로 확정하지 않는다.

## 참고

[1]: https://identity.kisa.or.kr/web/main/bbs/guide/44?cp=1&sortOrder=BA_REGDATE&sortDirection=DESC&bcId=guide&baNotice=false&baCommSelec=false&baOpenDay=false&baUse=true "KISA 본인확인서비스 이용기관 취약점 자체점검 체크리스트"
[2]: https://firebase.google.com/docs/rules "Firebase Security Rules 공식 문서"
[3]: https://firebase.google.com/docs/auth/admin/verify-id-tokens "Firebase ID 토큰 검증 공식 문서"
[4]: https://firebase.google.com/docs/auth/admin/custom-claims "Firebase Custom Claims 공식 문서"
