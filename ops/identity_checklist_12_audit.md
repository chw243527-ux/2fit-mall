# 2FIT MALL 본인확인 개인정보 보호 체크리스트 12개 점검 결과

점검일: 2026-08-31

기준은 사용자가 제공한 「본인확인 서비스 도입 시 개인정보 보호를 위한 체크리스트」 12개 항목이다. 현재 저장소에는 NICE아이디 CI/DI 연동 모듈이 없고 Firebase Phone Auth가 사용되므로, NICE 계약 후의 실제 CI/DI 암호화 응답 검증은 별도 구현이 필요하다. 아래 결과는 계약 전에 적용할 수 있는 공통 보안 통제와 현재 연동 방식에 대한 판정이다.

| 순번 | 점검 항목 | 현재 판정 | 확인·수정 결과 |
|---:|---|---|---|
| 1 | 불필요한 중요정보 평문 노출 | **적합(현재 범위)** | NICE CI/DI 값을 수집·화면 출력·URL 전달·Firestore 저장하는 코드가 없다. NICE 도입 시 CI/DI 원문을 프런트엔드·로그·쿼리스트링에 노출하지 않도록 서버 전용 처리로 추가해야 한다. |
| 2 | 파라미터 변조 | **적합(현재 Firebase 가입 흐름)** | 가입 문서 생성 시 인증 토큰의 전화번호와 문서 전화번호, 인증 이메일과 문서 이메일을 Firestore Rules에서 대조한다. 임의 `isAdmin`, `points`, 인증 상태 필드도 제한한다. |
| 3 | 동일인 여부 검증 | **적합(현재 전화번호 흐름)** | SMS로 인증된 Firebase 사용자를 임시 삭제하지 않고 동일 UID에 이메일 자격증명을 연결한다. 인증된 E.164 전화번호를 가입 문서에 저장하므로 가입 폼의 다른 번호를 별도로 주입할 수 없다. |
| 4 | 교차검증 | **NICE 연동 후 필수** | 현재 서비스에는 신분증·영상통화·계좌·보안카드·NICE 결과를 함께 비교하는 복수 본인확인 단계가 없다. NICE 계약 후 여러 결과값을 받는다면 동일 거래번호·동일 사용자·동일 전화번호/이름 등의 일치 검증을 서버에 추가해야 한다. |
| 5 | 인증결과 우회 | **적합(현재 가입·관리자 흐름)** | OTP 실패·미완료 상태에서는 `register()`가 중단되고, Firestore 생성 규칙도 Firebase Auth `phone_number`와 `phoneVerified`를 요구한다. 관리자 화면은 Custom Claim을 다시 확인한다. |
| 6 | 데이터 재사용 | **부분 적합** | Firebase OTP의 만료·실패 제한을 사용하고, 인증 결과를 앱 저장소에 보존하지 않는다. 다만 NICE 거래번호·암호화 응답의 서버 단발성 소비 처리는 아직 NICE 연동 전이므로 구현 대상이다. |
| 7 | 암호키 노출 | **적합(현재 범위)** | 저장소 검색에서 NICE 사이트 코드·클라이언트 시크릿·개인키가 발견되지 않았다. NICE 계약 후 키는 GitHub/웹 번들에 넣지 말고 배포 서버의 Secret 환경변수로만 주입해야 한다. |
| 8 | 데이터 위·변조 | **적합(현재 Firebase 흐름)** | 클라이언트가 작성한 전화번호·인증 상태·이메일을 임의 변경하지 못하도록 Firestore Rules에서 토큰과 문서를 비교하고, 일반 사용자 수정 필드를 화이트리스트로 제한했다. |
| 9 | 관리자 페이지 노출 | **적합(코드 기준)** | `/admin` 라우트는 관리자 화면을 직접 만들지 않고 로그인 화면으로 보낸다. `AdminScreen`도 렌더링 전 Custom Claim을 강제 재검증하며, 권한 확인 전 관리자 데이터 조회를 시작하지 않는다. |
| 10 | 데이터 평문 전송 | **적합(설정·운영 재검증 필요)** | 운영 도메인은 HTTPS를 사용하고 Firebase Hosting과 Cloudflare Pages 헤더에 HSTS, `nosniff`, `SAMEORIGIN`, Referrer-Policy를 적용했다. 배포 후 `2fit-mall.co.kr` 실제 응답 헤더를 다시 확인해야 한다. |
| 11 | 프로세스 검증 누락 | **적합(코드 기준)** | 관리자 중요 화면의 라우트·위젯·데이터 로딩을 각각 보호하며, 비밀번호 변경은 기존 비밀번호 재인증 후에만 수행한다. Firestore 민감 필드 변경도 일반 사용자에게 허용하지 않는다. |
| 12 | 쿠키 변조 | **현재 쿠키 미사용** | 인증 쿠키를 직접 사용하는 코드가 없으며 Firebase 웹 persistence와 PWA 설치 안내용 비민감 `localStorage` 플래그만 확인된다. NICE 세션 쿠키를 추가할 경우 `Secure`, `HttpOnly`, `SameSite=Lax/Strict`, 짧은 만료를 적용하고 중요 결과를 쿠키에 저장하지 않아야 한다. |

## 이번 수정 내역

`lib/services/auth_service.dart`에서 SMS 인증 사용자를 실제 가입 UID에 결속하고, 미인증 가입을 차단했으며, 일반 프로필 수정에서 전화번호 변경을 재인증 없이 수행할 수 없도록 했다. `firestore.rules`에는 인증 토큰과 사용자 문서의 전화번호·이메일 비교, 인증 상태 필드 보호, 사용자 수정 필드 화이트리스트가 적용되어 있다. `lib/main.dart`와 `lib/screens/admin/admin_screen.dart`에는 관리자 직접 접근 및 관리자 콘텐츠 선조회 차단을 적용했다. `web/_headers`에는 HSTS와 안전한 Permissions-Policy를 추가했다.

## 계약 전 최종 판단

**현재 코드 기준 공통 보안 통제는 보완되었지만, NICE아이디 계약 제출용으로 12개 항목 모두를 최종 ‘적합’으로 확정할 수는 없다.** 이유는 실제 NICE 연동이 아직 없어서 1·4·6·7·8번의 CI/DI 암호화 응답, 거래번호 일회성 검증, 키 관리, 위변조 검증을 운영 환경에서 입증할 수 없기 때문이다. NICE에서 발급하는 최신 개발가이드와 테스트 계정·사이트 코드·암호화 키·콜백 사양을 받은 뒤 서버 전용 연동을 추가하고, 운영 도메인에서 재검증한 후 제출하는 것이 안전하다.

## 검증 기록

`git diff --check`와 `functions` Node 문법 테스트는 통과했다. GitHub CI의 Flutter 분석·테스트와 Flutter Web 빌드는 새 보안 수정 커밋에서 확인해야 하며, Firebase Rules 실제 배포 검증은 Firebase CLI 인증이 필요하다.

## 참고

[1]: https://identity.kisa.or.kr/web/main/bbs/guide/44?cp=1&sortOrder=BA_REGDATE&sortDirection=DESC&bcId=guide&baNotice=false&baCommSelec=false&baOpenDay=false&baUse=true "KISA 본인확인서비스 이용기관 취약점 자체점검 체크리스트 및 보안가이드"
[2]: https://identity.kisa.or.kr/web/main/bbs/guide/75?cp=1&sortOrder=BA_REGDATE&sortDirection=DESC&bcId=guide&baNotice=false&baCommSelec=false&baOpenDay=false&baUse=true "KISA 체크리스트 공식 FAQ"
