# 2FIT MALL 보안 점검 핵심 기록

## 공식 참고자료

- Firebase ID 토큰 검증: https://firebase.google.com/docs/auth/admin/verify-id-tokens
- Firebase Firestore Rules 조건: https://firebase.google.com/docs/firestore/security/rules-conditions
- Toss Payments API 가이드: https://docs.tosspayments.com/en/api-guide
- npm 의존성 보안 감사: https://docs.npmjs.com/auditing-package-dependencies-for-security-vulnerabilities

## 점검 결과

- Firestore 기본 catch-all 규칙은 읽기·쓰기를 차단하고 관리자 권한은 Firebase Custom Claims를 사용함.
- Cloudflare Pages `functions/api/confirm-payment.js`와 `functions/api/issue-cash-receipt.js`는 기존에 Firebase ID 토큰 및 주문 소유권 검증 없이 공개 POST를 허용해 P0 보완 대상으로 분류함.
- Firestore users 업데이트 허용 필드와 클라이언트의 nickname/phone 저장 흐름이 불일치함. phone 및 인증 메타데이터는 서버 함수에서만 저장하도록 보완 필요.
- Storage `users/{userId}/...` 프로필 이미지 읽기가 공개로 설정되어 있어 개인정보성 이미지라면 비공개화 검토 필요.
- `npm audit --omit=dev`에서 중간 위험도 취약점 7건이 확인됨. `npm audit fix --force`는 breaking change 가능성이 있어 별도 브랜치와 회귀 테스트가 필요.
- 라이브 Toss client key는 앱·웹에 포함될 수 있는 공개 키이며 secret key는 서버 Secret Manager에 있어야 함.
- Firebase Functions `confirmSecurePayment`는 로그인 토큰, payment_intent 소유권, 금액, 만료, 멱등성을 확인하는 안전한 기준 경로로 확인됨.

## 공식 보안 수정 방향

Cloudflare 공개 결제 승인·현금영수증 경로 대신 인증된 Firebase Functions 경로를 사용하거나, Cloudflare에서 Firebase ID 토큰·주문 소유권·금액을 검증해야 함. 이번 수정은 인증된 Firebase Functions에 현금영수증 엔드포인트를 추가하고 클라이언트를 해당 경로로 전환하는 방향임.
