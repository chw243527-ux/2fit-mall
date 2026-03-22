#!/usr/bin/env python3
"""
2FIT MALL - Firebase Hosting 무료 배포 자동화 스크립트
=====================================================
사전 조건:
  - Node.js 설치: https://nodejs.org
  - Firebase CLI: npm install -g firebase-tools
  - Firebase 계정: https://console.firebase.google.com

실행: python3 scripts/deploy_firebase.py
"""

import os, subprocess, sys

FLUTTER_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

DEPLOY_STEPS = """
╔══════════════════════════════════════════════════════════╗
║       2FIT MALL Firebase Hosting 배포 가이드             ║
╚══════════════════════════════════════════════════════════╝

■ 1단계 - Firebase CLI 설치 (한 번만)
──────────────────────────────────────
npm install -g firebase-tools

■ 2단계 - Firebase 로그인
──────────────────────────────────────
firebase login

■ 3단계 - Flutter 웹 빌드 + 배포 (한 줄)
──────────────────────────────────────────
cd /home/user/flutter_app
flutter build web --release && firebase deploy --only hosting

■ 배포 완료 후 접속 URL
──────────────────────────────────────────
  https://fit-mall.web.app
  https://fit-mall.firebaseapp.com

■ 커스텀 도메인 연결 (2fit-mall.co.kr)
──────────────────────────────────────────
1. Firebase Console → Hosting → "사용자 지정 도메인 추가"
2. 도메인 소유권 확인 (TXT 레코드 추가)
3. DNS A 레코드를 Firebase IP로 설정
   → Firebase가 자동으로 SSL 인증서 발급

■ 배포 설정 파일 (firebase.json) - 이미 준비됨 ✅
──────────────────────────────────────────────────
- 모든 라우팅을 /index.html로 리다이렉트 (SPA)
- JS/CSS/폰트 1년 캐시 설정
- index.html 캐시 없음 (항상 최신 버전)
- 보안 헤더 자동 추가
"""

def run_deploy():
    print(DEPLOY_STEPS)

    ans = input("지금 바로 배포하시겠습니까? (y/n, flutter-tools 필요): ").strip().lower()
    if ans != 'y':
        print("\n위 가이드를 참조하여 수동으로 배포하세요.")
        return

    os.chdir(FLUTTER_DIR)

    print("\n🔨 Flutter 웹 빌드 중...")
    result = subprocess.run(
        ['flutter', 'build', 'web', '--release'],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print("❌ 빌드 실패:")
        print(result.stderr)
        sys.exit(1)
    print("✅ 빌드 완료!")

    print("\n🚀 Firebase Hosting 배포 중...")
    result = subprocess.run(
        ['firebase', 'deploy', '--only', 'hosting'],
        capture_output=True, text=True
    )
    if result.returncode != 0:
        print("❌ 배포 실패:")
        print(result.stderr)
        print("\n수동 배포: firebase login 후 firebase deploy --only hosting")
        sys.exit(1)

    print("✅ 배포 완료!")
    print("\n🌐 접속 URL: https://fit-mall.web.app")

if __name__ == '__main__':
    run_deploy()
