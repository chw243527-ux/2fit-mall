#!/usr/bin/env python3
"""
2FIT MALL - 커스텀 도메인 설정 완전 가이드
==========================================
도메인: 2fit-mall.co.kr
Firebase 프로젝트: fit-mall

실행: python3 scripts/domain_setup_guide.py
"""

GUIDE = """
╔══════════════════════════════════════════════════════════════════════╗
║           2FIT MALL 도메인 설정 완전 가이드                          ║
║           도메인: 2fit-mall.co.kr → Firebase Hosting                ║
╚══════════════════════════════════════════════════════════════════════╝

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 STEP 1: Flutter 웹 빌드 (로컬 PC에서)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  1. 프로젝트를 로컬로 다운로드 (GitHub 또는 zip)
  2. 터미널에서 실행:

     flutter build web --release

  3. build/web 폴더가 생성됨


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 STEP 2: Firebase CLI 설치 & 로그인
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  # Node.js 설치: https://nodejs.org (LTS 버전)

  # Firebase CLI 설치
  npm install -g firebase-tools

  # Firebase 로그인 (Google 계정)
  firebase login

  # 프로젝트 확인
  firebase projects:list


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 STEP 3: Firebase Hosting 배포
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  cd /path/to/flutter_app

  # 배포 (targeting 방식)
  firebase deploy --only hosting:production

  ✅ 배포 완료 후 접속:
     https://fit-mall.web.app
     https://fit-mall.firebaseapp.com


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 STEP 4: Firebase Console에서 커스텀 도메인 추가
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  1. Firebase Console 접속:
     https://console.firebase.google.com/project/fit-mall/hosting

  2. "사용자 지정 도메인 추가" 버튼 클릭

  3. 도메인 입력: 2fit-mall.co.kr
     (www.2fit-mall.co.kr 도 별도로 추가)

  4. "소유권 확인" 단계:
     Firebase가 TXT 레코드를 제공합니다.
     예시: google-site-verification=XXXXXXXX...

  5. DNS에 TXT 레코드 추가 후 "확인" 클릭


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 STEP 5: DNS 설정 (도메인 등록업체 관리 페이지)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  현재 도메인 상태:
  - 2fit-mall.co.kr → GitHub Pages (185.199.x.x)   ← 변경 필요!
  - www.2fit-mall.co.kr → GitHub Pages              ← 변경 필요!

  변경할 DNS 레코드:
  ┌─────────────────────────────────────────────────────────────┐
  │  유형   호스트명           값                               │
  ├─────────────────────────────────────────────────────────────┤
  │  A      @  (루트)         151.101.1.195    ← Firebase IP   │
  │  A      @  (루트)         151.101.65.195   ← Firebase IP   │
  │  CNAME  www               2fit-mall.co.kr                  │
  │  TXT    @                 [Firebase 제공 인증 코드]         │
  └─────────────────────────────────────────────────────────────┘

  ⚠️ 기존 GitHub Pages A 레코드 (185.199.x.x) 는 모두 삭제!

  주요 도메인 등록업체 관리 페이지:
  - 가비아:  https://dns.gabia.com
  - 카페24:  https://www.cafe24.com/dns
  - 후이즈:  https://www.whois.co.kr
  - 아이네임즈: https://www.inames.co.kr


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 STEP 6: SSL 인증서 자동 발급 대기
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  DNS 변경 후 Firebase가 자동으로:
  ✅ Let's Encrypt SSL 인증서 발급 (무료)
  ✅ HTTPS 강제 리다이렉트 설정
  ✅ CDN 배포 (전 세계 빠른 속도)

  소요 시간: DNS 전파 24~48시간 (보통 1~2시간 내 완료)

  확인 방법:
  Firebase Console → Hosting → 도메인 상태 "연결됨" 확인


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 STEP 7: www → 루트 도메인 리다이렉트 설정 (선택)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Firebase Console에서 www.2fit-mall.co.kr 추가 시:
  - "2fit-mall.co.kr 으로 리다이렉트" 옵션 선택

  또는 firebase.json에서 리다이렉트 설정:
  (이미 CNAME www → @로 설정하면 자동 처리)


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Firebase 인증 도메인 업데이트 (필수!)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Firebase Console → Authentication → Settings → 승인된 도메인

  다음 도메인 추가:
  ✅ 2fit-mall.co.kr
  ✅ www.2fit-mall.co.kr

  이미 있는 도메인:
  - fit-mall.web.app (기본)
  - fit-mall.firebaseapp.com (기본)


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 앱 코드 내 도메인 업데이트 (이미 완료됨 ✅)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  lib/utils/constants.dart:
  ✅ appUrl = 'https://2fit-mall.co.kr'
  ✅ shopUrl = 'https://2fit-mall.co.kr'

  lib/services/email_service.dart:
  ✅ origin: 'https://2fit-mall.co.kr'
  ✅ shop_url: 'https://2fit-mall.co.kr'

  ⚠️ Firebase Auth Domain은 fit-mall.firebaseapp.com 유지 (정상)


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Google 로그인 OAuth 도메인 업데이트
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Google Cloud Console:
  https://console.cloud.google.com/apis/credentials

  OAuth 2.0 클라이언트 ID (웹 애플리케이션):
  → 승인된 JavaScript 원본에 추가:
    https://2fit-mall.co.kr
    https://www.2fit-mall.co.kr

  → 승인된 리다이렉션 URI에 추가:
    https://2fit-mall.co.kr/__/auth/handler
    https://www.2fit-mall.co.kr/__/auth/handler


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 최종 확인 체크리스트
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  □ flutter build web --release 완료
  □ firebase deploy --only hosting:production 완료
  □ DNS A 레코드 Firebase IP로 변경
  □ Firebase Console에서 커스텀 도메인 추가 및 소유권 확인
  □ Firebase Authentication 승인 도메인에 추가
  □ Google OAuth 도메인 추가
  □ https://2fit-mall.co.kr 접속 확인
  □ HTTPS 인증서 발급 확인 (브라우저 자물쇠 아이콘)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 완료 예상 URL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  🌐 메인:   https://2fit-mall.co.kr
  🌐 www:    https://www.2fit-mall.co.kr  →  https://2fit-mall.co.kr
  🔥 Firebase: https://fit-mall.web.app
  🔥 Mirror:   https://fit-mall.firebaseapp.com

"""

if __name__ == "__main__":
    print(GUIDE)
