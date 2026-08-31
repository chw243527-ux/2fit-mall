# NICE 본인확인 자가점검 — 조사 메모

## 운영 사이트 확인

- 확인 시각: 2026-08-31 GMT+9
- URL: `https://2fit-mall.co.kr/`
- HTTPS로 접속되었으며, 초기 화면 로딩 후 로그인 페이지가 표시됨.
- 로그인 페이지에는 이메일·비밀번호 로그인, 카카오·네이버·Google 로그인, 회원가입 진입점이 노출됨.

## 코드 구조 확인

- 회원가입은 `lib/screens/auth/signup_screen.dart`, 인증·회원 데이터 처리는 `lib/services/auth_service.dart`에 구현됨.
- 가입 화면은 Firebase Phone Auth SMS OTP를 요구하지만, 인증 성공 상태는 클라이언트 상태 변수 `_phoneVerified`로만 유지됨.
- `AuthService.register()`는 전화번호 인증 증빙 또는 검증된 전화번호을 매개변수로 요구·검증하지 않고 Firebase 이메일/비밀번호 계정을 생성함.
- Firestore `users/{uid}` 규칙은 사용자의 본인 문서 생성·수정을 허용하며, 가입 전화번호 인증 여부·본인확인값(CI/DI)·이메일 일치 여부를 서버 측에서 강제하지 않음.
- 코드 검색상 NICE 아이디 연동 및 CI/DI 수집·저장 구현은 발견되지 않음. 민감한 본인확인값은 현재 코드에 직접 저장되지 않는 것으로 보임.
- Firebase Hosting 설정은 HSTS, `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy` 헤더를 설정함.
- Cloud Functions의 결제 승인 경로는 서버 비밀값을 사용하며 서버 재계산, 인증 토큰 검증, 요청 제한, 결제 금액·주문 ID 대조를 수행함.

## 해석 유의사항

- 이 메모는 저장소 정적 코드와 비로그인 운영 화면 확인에 근거함. Firebase Console, 실제 배포된 규칙/환경변수, NICE 관리자 설정 및 침투 테스트 결과는 별도 확인이 필요함.

## 운영 관리자 경로 확인

- 비로그인 상태에서 `https://2fit-mall.co.kr/#/admin`에 직접 접속했을 때, 로그인 화면으로 리디렉션되지 않고 관리자 대시보드 UI가 표시되었음.
- 화면에 주문관리·배송관리·회원관리·매출통계 등 민감 운영 기능의 메뉴 구조가 노출되었고, 화면 값은 모두 0으로 보였음.
- Firestore 및 Cloud Functions에는 관리자 Custom Claim 기반의 서버 측 권한 검사가 존재하므로 실제 고객 데이터/변경 기능 접근이 막힐 가능성이 높으나, 비로그인 사용자에게 관리자 중요 페이지 자체를 노출하므로 UI 라우트 가드는 미충족으로 판단함.

## 전송구간 확인

- `https://2fit-mall.co.kr/`은 유효한 Google Trust Services 인증서로 TLS 1.2(ECDHE-ECDSA-CHACHA20-POLY1305) 협상 및 인증서 검증에 성공함.
- TLS 1.1 연결은 암호군 협상에 실패하여 구형 프로토콜이 실질적으로 차단된 것으로 관찰됨.
- 운영 응답에는 `X-Frame-Options`, `X-Content-Type-Options`, `Referrer-Policy`, `Permissions-Policy`가 있었으나, 저장소의 Firebase 설정에 기재된 HSTS 응답 헤더는 실제 응답에서 확인되지 않았음. 운영 도메인이 Netlify/Cloudflare로 제공되는 것으로 보이며 배포 설정 동기화가 필요함.
