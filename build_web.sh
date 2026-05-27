#!/bin/bash
set -e
cd /home/user/flutter_app

echo "=== Flutter web 빌드 시작 ==="
flutter build web --release

echo "=== buildConfig renderer: canvaskit → html 패치 ==="
sed -i 's/"renderer":"canvaskit"/"renderer":"html"/g' build/web/flutter_bootstrap.js
echo "패치 완료: $(grep -o '"renderer":"[^"]*"' build/web/flutter_bootstrap.js)"

echo "=== 서버 재시작 ==="
kill -9 $(lsof -t -i:5060 2>/dev/null) 2>/dev/null || true
sleep 1
cd build/web && nohup python3 -m http.server 5060 --bind 0.0.0.0 > /tmp/srv.log 2>&1 &
sleep 2
curl -sI http://localhost:5060 | head -2
echo "=== 완료 ==="
