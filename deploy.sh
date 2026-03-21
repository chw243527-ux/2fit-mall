#!/bin/bash
# 2FIT MALL 배포 스크립트 - CNAME 자동 복구 포함
# 사용법: TOKEN=ghp_xxx ./deploy.sh
set -e

REPO="chw243527-ux/2fit-mall"
# 토큰은 환경변수로 전달하세요: export TOKEN=ghp_xxxxx
TOKEN="${TOKEN:-}"
CNAME_DOMAIN="2fit-mall.co.kr"

if [ -z "$TOKEN" ]; then
  echo "❌ TOKEN 환경변수가 필요합니다."
  echo "   사용법: TOKEN=ghp_xxxxx ./deploy.sh"
  exit 1
fi

echo "🔨 Flutter 웹 빌드 중..."
cd /home/user/flutter_app
flutter build web --release --base-href "/" 2>&1 | tail -3

echo "📦 gh-pages 배포 중..."
cd /tmp && rm -rf ghpages_deploy && mkdir ghpages_deploy && cd ghpages_deploy
git init && git checkout -b gh-pages
cp -r /home/user/flutter_app/build/web/. .
echo "$CNAME_DOMAIN" > CNAME
git config user.email "deploy@fitfashion.com"
git config user.name "Deploy Bot"
git add -A
git commit -m "deploy: $(date '+%Y-%m-%d %H:%M')"
git remote add origin "https://${TOKEN}@github.com/${REPO}.git"
git push -f origin gh-pages

echo "⚙️  GitHub Pages CNAME 설정 중..."
sleep 5

# CNAME API 설정 (최대 3회 재시도)
for i in 1 2 3; do
  RESULT=$(curl -s -X PUT \
    -H "Authorization: token $TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "Content-Type: application/json" \
    "https://api.github.com/repos/${REPO}/pages" \
    -d "{\"cname\":\"${CNAME_DOMAIN}\",\"https_enforced\":false}" 2>&1)
  
  if echo "$RESULT" | grep -q "certificate does not exist"; then
    echo "  ⏳ 인증서 대기 중... ($i/3)"
    sleep 10
  else
    echo "  ✅ CNAME 설정 완료"
    break
  fi
done

# 빌드 완료 대기
echo "⏳ GitHub Pages 빌드 완료 대기..."
for i in $(seq 1 10); do
  STATUS=$(curl -s -H "Authorization: token $TOKEN" \
    "https://api.github.com/repos/${REPO}/pages" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('status',''))")
  if [ "$STATUS" = "built" ]; then
    CNAME=$(curl -s -H "Authorization: token $TOKEN" \
      "https://api.github.com/repos/${REPO}/pages" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('cname',''))")
    echo "✅ 배포 완료! status=$STATUS, cname=$CNAME"
    echo "🌐 https://${CNAME_DOMAIN}"
    exit 0
  fi
  sleep 5
done

echo "⚠️  빌드 시간이 오래 걸립니다. 잠시 후 접속해 주세요."
echo "🌐 https://${CNAME_DOMAIN}"
