#!/bin/bash
# 2FIT MALL - 빌드 & 배포 자동화 스크립트

set -e

echo "🔨 Flutter 웹 빌드 시작..."
cd /home/user/flutter_app
flutter build web --release

echo "🔧 Service Worker 비활성화 (항상 최신 버전 로드)..."
python3 -c "
import re
with open('build/web/flutter_bootstrap.js', 'r') as f:
    content = f.read()
content = re.sub(
    r'serviceWorkerSettings:\s*\{[^}]*\}',
    'serviceWorkerSettings: null',
    content
)
# 기존 Service Worker 등록도 제거
with open('build/web/flutter_service_worker.js', 'w') as f:
    f.write('// Service Worker disabled for immediate updates\nself.addEventListener(\"install\", e => self.skipWaiting());\nself.addEventListener(\"activate\", e => e.waitUntil(clients.claim()));\nself.addEventListener(\"fetch\", e => e.respondWith(fetch(e.request)));\n')
with open('build/web/flutter_bootstrap.js', 'w') as f:
    f.write(content)
print('✅ Service Worker 비활성화 완료')
"

echo "🚀 Netlify 배포 중..."
export PATH=\$PATH:/home/user/.npm-global/bin
export NETLIFY_AUTH_TOKEN=nfp_h3vGi6yJAG3HVsYqJ5vDGHX164hoZwZ7aaba
export NETLIFY_SITE_ID=13020fb8-6e95-4ab0-b387-644cb5401473
netlify deploy --prod --dir=build/web --site=\$NETLIFY_SITE_ID

echo ""
echo "✅ 배포 완료! https://2fit-mall.netlify.app"
