#!/bin/bash
# Netlify PR 프리뷰 빌드 스크립트
# Flutter SDK 설치 후 웹 빌드 실행
set -e

FLUTTER_VERSION="${FLUTTER_VERSION:-3.32.2}"
FLUTTER_DIR="$HOME/flutter"

echo "=== Flutter $FLUTTER_VERSION 설치 시작 ==="

if [ ! -f "$FLUTTER_DIR/bin/flutter" ]; then
  echo "Flutter SDK 다운로드 중..."
  FLUTTER_URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
  curl -L "$FLUTTER_URL" -o /tmp/flutter.tar.xz
  mkdir -p "$HOME"
  tar -xJf /tmp/flutter.tar.xz -C "$HOME"
  # 압축 해제 결과: $HOME/flutter/
  rm -f /tmp/flutter.tar.xz
  echo "Flutter SDK 설치 완료: $FLUTTER_DIR"
else
  echo "기존 Flutter SDK 사용: $FLUTTER_DIR"
fi

export PATH="$PATH:$FLUTTER_DIR/bin"
export FLUTTER_ROOT="$FLUTTER_DIR"

echo "=== Flutter 버전 ==="
flutter --version

echo "=== 의존성 설치 ==="
flutter pub get

echo "=== 웹 빌드 ==="
flutter build web --release --tree-shake-icons

echo "=== 빌드 완료 ==="
ls build/web/ | head -5
