#!/bin/bash
# ============================================================
#  2FIT MALL - Firebase Hosting 배포 + 커스텀 도메인 연결
#  실행: bash scripts/deploy_and_domain.sh
# ============================================================

set -e  # 오류 발생 시 즉시 중단

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║       2FIT MALL Firebase Hosting 배포 자동화             ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# 1. Firebase CLI 확인
echo -e "${YELLOW}[1/5] Firebase CLI 확인...${NC}"
if ! command -v firebase &> /dev/null; then
    echo "Firebase CLI가 없습니다. 설치 중..."
    npm install -g firebase-tools
fi
echo -e "${GREEN}✅ Firebase CLI $(firebase --version)${NC}"

# 2. Firebase 로그인
echo -e "${YELLOW}[2/5] Firebase 로그인 확인...${NC}"
if ! firebase projects:list &> /dev/null; then
    echo "Firebase 로그인이 필요합니다."
    firebase login
fi
echo -e "${GREEN}✅ Firebase 로그인 완료${NC}"

# 3. Flutter 웹 빌드
echo -e "${YELLOW}[3/5] Flutter 웹 릴리즈 빌드...${NC}"
cd "$(dirname "$0")/.."
flutter build web --release
echo -e "${GREEN}✅ 빌드 완료 (build/web)${NC}"

# 4. Firebase Hosting 배포
echo -e "${YELLOW}[4/5] Firebase Hosting 배포 중...${NC}"
firebase deploy --only hosting --project fit-mall
echo -e "${GREEN}✅ 배포 완료!${NC}"

# 5. 결과 출력
echo ""
echo -e "${GREEN}"
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                    배포 성공! 🎉                         ║"
echo "╠══════════════════════════════════════════════════════════╣"
echo "║  기본 URL:  https://fit-mall.web.app                    ║"
echo "║  미러 URL:  https://fit-mall.firebaseapp.com            ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${YELLOW}다음 단계: 아래 가이드에 따라 커스텀 도메인을 연결하세요.${NC}"
echo ""
cat <<'DOMAIN_GUIDE'
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  커스텀 도메인 연결: 2fit-mall.co.kr
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

■ Firebase Console에서:
  1. https://console.firebase.google.com/project/fit-mall/hosting
  2. "사용자 지정 도메인 추가" 클릭
  3. 도메인 입력: 2fit-mall.co.kr
  4. TXT 레코드 확인 후 → DNS에 추가

■ DNS 설정 (도메인 등록업체에서):
  ┌──────────────────────────────────────────────┐
  │ 유형  호스트  값                              │
  ├──────────────────────────────────────────────┤
  │ A     @       151.101.1.195                  │
  │ A     @       151.101.65.195                 │
  │ CNAME www     2fit-mall.co.kr                │
  └──────────────────────────────────────────────┘

■ Firebase가 자동으로 처리:
  - SSL 인증서 자동 발급 (Let's Encrypt)
  - HTTPS 강제 리다이렉트
  - CDN 배포 (전 세계 빠른 속도)

DOMAIN_GUIDE
