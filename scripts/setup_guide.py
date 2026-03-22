#!/usr/bin/env python3
"""
2FIT MALL - 실제 서비스 구동을 위한 전체 설정 가이드
====================================================
이 파일은 실제 서비스 전환을 위한 모든 설정을 안내합니다.
"""

SETUP_GUIDE = """
╔══════════════════════════════════════════════════════════╗
║        2FIT MALL 실제 서비스 구동 설정 가이드            ║
╚══════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
■ 1단계: Firebase 설정 (필수)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1-1. Firebase Console 접속
     URL: https://console.firebase.google.com/project/fit-mall

1-2. Firestore Database 생성 (아직 없다면)
     Build → Firestore Database → Create Database
     - 모드: Production mode
     - 위치: asia-northeast3 (서울)

1-3. Authentication 활성화
     Build → Authentication → Sign-in method
     - Email/Password → Enable ✓
     - Google → Enable ✓ (소셜 로그인)

1-4. Firestore 보안 규칙 배포
     터미널에서: firebase deploy --only firestore:rules
     (firestore.rules 파일이 이미 준비되어 있습니다)

1-5. Firebase Admin SDK 키 발급
     Project Overview → Project Settings → Service Accounts
     → Python 선택 → "새 비공개 키 생성"
     → 다운로드된 JSON 파일 저장

1-6. 데이터 초기화
     python3 scripts/init_firestore_data.py

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
■ 2단계: 토스페이먼츠 결제 설정
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

2-1. 토스페이먼츠 계정 생성
     URL: https://developers.tosspayments.com

2-2. 테스트 모드 설정 (개발/테스트용)
     현재 설정된 테스트 키:
     - Client Key: test_ck_D5GePWvyJnrK0W0k6q8gLzN97Eoq
     - Secret Key: test_sk_zXLkKEypNArWmo50nX3lmeaxYG5R
     → lib/services/payment_service.dart 에서 변경 가능

2-3. 실결제 전환 방법
     lib/services/payment_service.dart 수정:
     ```dart
     static const clientKey = '실제_client_key';  // 여기 교체
     static const secretKey = '실제_secret_key';  // 서버에서만 사용!
     ```
     ⚠️ secretKey는 절대 앱에 포함 금지!
     → Supabase Edge Function 또는 별도 서버 사용 권장

2-4. 결제 승인 서버 (선택사항 - 보안 강화)
     Supabase Edge Function 예시:
     - URL: https://YOUR_PROJECT.supabase.co/functions/v1/confirm-payment
     - lib/services/payment_service.dart의 confirmEdgeFunctionUrl 설정

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
■ 3단계: FCM 푸시 알림 설정
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

3-1. FCM 웹 VAPID 키 설정
     Firebase Console → Project Settings → Cloud Messaging
     → Web Push certificates → Generate key pair
     → 발급된 키를 lib/services/fcm_service.dart에 입력:
     ```dart
     _currentToken = await messaging.getToken(
       vapidKey: '여기에_VAPID_키_입력',
     ).catchError((_) => null);
     ```

3-2. Android FCM 설정 (APK 빌드 시)
     - google-services.json 파일을 android/app/ 에 복사
     - Firebase Console에서 Android 앱 등록 (패키지명: com.twofit.twofitMall)

3-3. FCM 서버 알림 발송 (선택사항)
     Admin SDK 키로 서버에서 알림 발송:
     ```python
     from firebase_admin import messaging
     message = messaging.Message(
         notification=messaging.Notification(
             title='2FIT MALL',
             body='새로운 이벤트가 시작되었습니다!',
         ),
         topic='all_users',
     )
     response = messaging.send(message)
     ```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
■ 4단계: 카카오 API 설정
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

4-1. 카카오 주소 API (현재 동작 중)
     - 다음 우편번호 서비스 기반 (별도 키 불필요)
     - lib/widgets/kakao_address_search.dart에 구현됨

4-2. 카카오 채널 연결 (@2fitkorea)
     - 앱 내 카카오 채널 버튼 설정 완료
     - 실제 채널: https://pf.kakao.com/_2fitkorea

4-3. 카카오 소셜 로그인 (선택사항)
     - https://developers.kakao.com 에서 앱 등록
     - 앱 키를 lib/services/auth_service.dart에 추가

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
■ 5단계: Google Sign-In 설정
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

5-1. Firebase Console → Authentication → Google 활성화
5-2. 웹 클라이언트 ID 확인:
     Firebase Console → Authentication → Google → 웹 SDK 구성
     → 웹 클라이언트 ID 복사

5-3. web/index.html의 Google Sign-In 클라이언트 ID 수정:
     <meta name="google-signin-client_id" content="YOUR_CLIENT_ID.apps.googleusercontent.com">

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
■ 6단계: 배포
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

6-1. Firebase Hosting (무료, 권장)
     ```bash
     npm install -g firebase-tools
     firebase login
     cd /home/user/flutter_app
     flutter build web --release
     firebase deploy
     ```
     배포 URL: https://fit-mall.web.app

6-2. Netlify (무료, 대안)
     ```bash
     flutter build web --release
     # build/web 폴더를 Netlify에 업로드
     # 또는 GitHub 연동으로 자동 배포
     ```

6-3. 커스텀 도메인 연결 (2fit-mall.co.kr)
     - Firebase Hosting: 프로젝트 → Hosting → Custom domain 추가
     - DNS 설정: CNAME 레코드를 Firebase 호스팅 주소로 설정

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
■ 7단계: 이메일 서비스 설정 (주문 확인 이메일)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

7-1. 현재 설정: EmailJS 또는 SMTP 서버 사용
     lib/services/email_service.dart 참조

7-2. SendGrid 설정 (권장)
     - https://sendgrid.com 에서 API 키 발급
     - lib/services/email_service.dart에 API 키 설정

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
■ 8단계: 관리자 계정 설정
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

현재 관리자 이메일:
- admin@2fitkorea.com (메인 관리자)
- cs@2fitkorea.com (CS 관리자)
- manager@2fit.co.kr (매니저)

설정 방법:
1. Firebase Authentication에서 위 이메일로 계정 생성
2. Firestore의 users/{uid} 문서에 isAdmin: true 설정
   또는 scripts/init_firestore_data.py 실행

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
■ 완료 체크리스트
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

필수 (최소 구동 조건):
[ ] Firestore Database 생성
[ ] Authentication 이메일 로그인 활성화
[ ] scripts/init_firestore_data.py 실행 (상품 데이터 입력)
[ ] firebase deploy --only firestore:rules (보안 규칙)

선택 (서비스 완성):
[ ] 토스페이먼츠 실결제 키 적용
[ ] FCM VAPID 키 설정
[ ] Google Sign-In 클라이언트 ID 설정
[ ] 도메인 연결 (2fit-mall.co.kr)
[ ] 이메일 서비스 설정
"""

if __name__ == '__main__':
    print(SETUP_GUIDE)
