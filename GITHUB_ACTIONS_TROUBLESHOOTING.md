# 2FIT MALL GitHub Actions 배포 트러블슈팅 가이드

## 1. 배포 흐름과 로그 확인 순서

현재 워크플로는 다음 순서로 실행됩니다.

| 순서 | 단계 | 실패 시 영향 |
|---:|---|---|
| 1 | Checkout repository | 이후 모든 단계가 실행되지 않음 |
| 2 | Node.js·Flutter 설치 | 빌드와 Functions 배포가 모두 중단됨 |
| 3 | Flutter 의존성 설치·분석 | 웹 빌드가 중단됨 |
| 4 | Flutter Web 빌드 | Firebase·Cloudflare 배포가 실행되지 않음 |
| 5 | 웹 서비스 워커 검증·캐시버스팅 | 잘못된 웹 산출물 배포를 방지하고 중단됨 |
| 6 | Firebase CLI·Functions 의존성 설치 | Firebase 배포가 중단됨 |
| 7 | Firebase 인증 | Rules·Storage·Functions 배포가 중단됨 |
| 8 | Firestore Rules·Storage Rules·Functions 배포 | Cloudflare Pages 배포가 실행되지 않음 |
| 9 | Cloudflare Pages 배포 | 웹 운영 반영이 중단됨 |
| 10 | Cloudflare 캐시 purge | 사이트는 배포됐지만 이전 캐시가 남을 수 있음 |

GitHub에서 `Actions → Build & Deploy — Firebase + Cloudflare Pages → 실패한 실행 → 실패한 Step` 순서로 들어가면 상세 로그를 확인할 수 있습니다. 로그에서 먼저 찾아야 할 정보는 **실패한 Step 이름**, 오류가 처음 발생한 줄, `exit code`, 그리고 오류 직전의 환경·파일 경로입니다.

> 로그 전체를 처음부터 읽기보다 실패한 Step의 마지막 30~50줄과 오류가 처음 발생한 위치를 함께 확인하는 방식이 효율적입니다.

## 2. 가장 자주 발생하는 오류

### 2.1 GitHub Actions가 실행되지 않음

| 증상 | 가능 원인 | 확인·해결 |
|---|---|---|
| `main`에 push했지만 실행 기록이 없음 | 워크플로 파일이 아직 `main`에 push되지 않음 | `.github/workflows/deploy.yml`이 GitHub의 `main` 브랜치에 존재하는지 확인 |
| Actions가 비활성화됨 | 저장소 또는 조직 설정에서 Actions 제한 | `Settings → Actions → General`에서 허용 상태 확인 |
| Workflow가 보이지 않음 | YAML 파일 위치가 잘못됨 | 반드시 `.github/workflows/deploy.yml` 위치 사용 |
| `workflow_dispatch` 버튼 없음 | 워크플로가 기본 브랜치에 아직 반영되지 않음 | 먼저 `main`에 커밋하고 Actions 페이지 새로고침 |
| 실행이 취소됨 | 동일 브랜치의 새 실행이 이전 실행을 취소 | `concurrency.cancel-in-progress` 동작. 최신 실행 결과를 확인 |

로컬에서 파일 위치를 확인합니다.

```bash
test -f .github/workflows/deploy.yml && echo OK
git status
git log -1 --oneline
```

### 2.2 Checkout 실패

대표 오류는 다음과 같습니다.

```text
Repository not found
Failed to fetch
Permission denied
```

저장소가 private으로 바뀌었거나 조직 정책이 `actions/checkout`을 제한하는 경우 발생할 수 있습니다. 공개 저장소라면 보통 별도 토큰이 필요하지 않습니다. private 저장소라면 저장소 Actions 권한과 조직의 Actions 정책을 확인합니다.

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 1
```

### 2.3 Flutter 버전 또는 SDK 설치 실패

대표 오류는 다음과 같습니다.

```text
Flutter version 3.32.2 not found
Unable to find a version that satisfies the requirement
```

워크플로의 버전과 프로젝트가 요구하는 버전이 일치하는지 확인합니다.

```yaml
env:
  FLUTTER_VERSION: '3.32.2'
```

Flutter SDK 다운로드가 일시적으로 실패한 경우 Actions의 **Re-run failed jobs**를 사용합니다. 동일하게 반복되면 `subosito/flutter-action` 버전과 Flutter 릴리스의 실제 존재 여부를 확인합니다.

### 2.4 Flutter 패키지 설치 실패

대표 오류는 다음과 같습니다.

```text
Because ... depends on ... version solving failed
pub get failed
Could not resolve dependencies
```

먼저 로컬에서 동일 버전을 사용해 재현합니다.

```bash
flutter --version
flutter clean
rm -rf .dart_tool
flutter pub get
```

`pubspec.yaml`을 변경했다면 반드시 `pubspec.lock`도 함께 검토합니다. CI는 `pubspec.lock`을 기준으로 캐시 키를 생성하므로, 의존성 변경 후에도 이전 캐시가 계속 사용되면 GitHub Actions의 `skip_cache` 입력값을 `true`로 설정해 수동 실행합니다.

```text
Actions → 해당 Workflow → Run workflow → skip_cache: true
```

### 2.5 `flutter analyze` 실패

대표 오류는 다음과 같습니다.

```text
error • Undefined name
error • Target of URI doesn't exist
error • The method ... isn't defined
```

이 단계는 경고보다 **error**가 중요합니다. 로컬에서 동일하게 실행합니다.

```bash
flutter pub get
flutter analyze
```

소스가 조건부 import를 사용하는 경우 웹에서만 분석되는 코드와 Android에서만 분석되는 코드가 다를 수 있습니다. 가능하면 CI에 다음 검사를 추가해 플랫폼별 문제를 조기에 발견합니다.

```bash
flutter analyze
flutter build web --release
flutter build apk --debug --target-platform android-arm64
```

### 2.6 Flutter 웹 빌드 실패

대표 오류는 다음과 같습니다.

```text
Target of URI doesn't exist: dart:html
Unsupported operation
Compilation failed
```

웹 전용 API는 조건부 import로 분리되어 있어야 합니다. `dart:html`, `dart:js`, `dart:js_interop`를 공통 파일에서 직접 import하지 않는지 확인합니다.

```bash
grep -RInE "dart:(html|js|js_interop)" lib --include='*.dart'
```

웹 빌드 결과가 생성되지 않으면 다음 파일을 확인합니다.

```text
build/web/index.html
build/web/flutter_bootstrap.js
build/web/main.dart.js
```

### 2.7 웹 서비스 워커 검증 실패

현재 워크플로는 다음 파일을 필수로 확인합니다.

```text
build/web/firebase-messaging-sw.js
build/web/flutter_service_worker.js
```

대표 오류는 다음과 같습니다.

```text
firebase-messaging-sw.js not found
flutter_service_worker.js not found
Firebase Messaging worker check failed
```

로컬에서 확인합니다.

```bash
flutter build web --release
test -f build/web/firebase-messaging-sw.js
test -f build/web/flutter_service_worker.js
grep -n "firebase-messaging-compat" build/web/firebase-messaging-sw.js
grep -n "flutter_service_worker.js" build/web/firebase-messaging-sw.js
```

웹 FCM 서비스 워커의 SDK URL이 404를 반환하지 않는지도 확인합니다. 파일에는 버전이 포함된 Firebase SDK URL이 있어야 합니다.

```javascript
importScripts('https://www.gstatic.com/firebasejs/10.13.0/firebase-messaging-compat.js');
```

### 2.8 Firebase Secret 누락

대표 오류는 다음과 같습니다.

```text
GOOGLE_APPLICATION_CREDENTIALS_JSON Secret이 설정되지 않았습니다.
```

GitHub 저장소에서 다음 위치를 확인합니다.

```text
Settings
→ Secrets and variables
→ Actions
→ Repository secrets
```

필수 Secret은 다음과 같습니다.

| Secret | 필수 여부 | 용도 |
|---|---:|---|
| `GOOGLE_APPLICATION_CREDENTIALS_JSON` | 필수 | Firebase Rules·Storage·Functions 배포 |
| `CLOUDFLARE_API_TOKEN` | 필수 | Cloudflare Pages 배포 |
| `CLOUDFLARE_ACCOUNT_ID` | 필수 | Cloudflare 계정 식별 |
| `CLOUDFLARE_ZONE_ID` | 선택 | 캐시 purge |

Secret 이름은 대소문자와 밑줄까지 정확히 일치해야 합니다. Secret 값은 로그에 직접 출력하지 않습니다.

### 2.9 Firebase 인증 실패

대표 오류는 다음과 같습니다.

```text
Failed to authenticate
Unable to acquire application default credentials
invalid_grant
```

서비스 계정 JSON이 올바른 JSON인지, 줄바꿈이 깨지지 않았는지 확인합니다. GitHub Secret에는 JSON 파일의 **전체 내용**을 저장해야 합니다.

로컬에서 JSON 형식만 확인하려면 Secret 값을 출력하지 않고 파일 자체에 대해 다음을 실행합니다.

```bash
python3 -m json.tool service-account.json >/dev/null && echo valid
```

서비스 계정에 최소한 다음 권한이 필요합니다.

| 권한 범위 | 필요한 역할 예시 |
|---|---|
| Firestore Rules | Firebase Rules Admin 또는 프로젝트 배포 권한 |
| Storage Rules | Storage Admin 또는 프로젝트 배포 권한 |
| Cloud Functions | Cloud Functions Admin, Service Account User 등 배포에 필요한 권한 |
| 프로젝트 조회 | Firebase Project Viewer 이상 |

서비스 계정 JSON을 GitHub에 일반 파일로 커밋하면 안 됩니다. 반드시 Repository secret 또는 더 안전한 GitHub OIDC/WIF 방식으로 관리합니다.

### 2.10 Firebase Rules 배포 실패

대표 오류는 다음과 같습니다.

```text
Error: HTTP Error: 400, Validation error
Error: Compilation error in firestore.rules
Error: Compilation error in storage.rules
```

Rules 파일의 문법과 줄 번호를 확인합니다. 로컬 Firebase Emulator를 사용하는 경우 다음처럼 검증할 수 있습니다.

```bash
firebase emulators:start --only firestore,storage
```

또는 배포 전에 개별적으로 실행해 어느 파일이 실패하는지 확인합니다.

```bash
firebase deploy --only firestore:rules --project fit-mall
firebase deploy --only storage --project fit-mall
```

특히 다음 항목을 확인합니다.

| 점검 항목 | 주의사항 |
|---|---|
| `firestore.get()` 경로 | `/databases/(default)/documents/...` 형식 사용 |
| 사용자 ID 필드 | 실제 문서 필드명과 `userId`가 일치해야 함 |
| `request.resource` | 생성·수정 시 사용. 삭제에서는 새 리소스가 없음 |
| Storage `request.resource.size` | 업로드·수정 시 사용 |
| recursive wildcard | 기존 파일 경로와 새 경로의 매칭 여부 확인 |
| 기본 거부 규칙 | 별도 match가 없는 컬렉션은 거부됨 |

이번 Storage 규칙은 사용자 ID 없는 기존 단체주문 경로를 차단합니다.

```text
group_orders/{orderId}/...
```

새 경로는 다음과 같습니다.

```text
group_orders/{userId}/{orderId}/...
```

기존 첨부파일이 있다면 먼저 마이그레이션해야 합니다.

### 2.11 Cloud Functions 의존성 설치 실패

대표 오류는 다음과 같습니다.

```text
npm ci can only install packages when package-lock.json is in sync
Unsupported engine
Module not found
```

`functions/package-lock.json`이 `functions/package.json`과 동기화되어 있는지 확인합니다.

```bash
cd functions
npm install
npm ci
npm ls --depth=0
```

의존성을 변경한 경우 다음 파일을 함께 커밋해야 합니다.

```text
functions/package.json
functions/package-lock.json
```

Node.js 버전도 확인합니다.

```yaml
env:
  NODE_VERSION: '20.x'
```

`functions/package.json`의 `engines.node`도 같은 메이저 버전을 사용해야 합니다.

### 2.12 Cloud Functions 배포 실패

대표 오류는 다음과 같습니다.

```text
HTTP Error: 403
Permission denied
Cloud Functions deployment requires the Blaze plan
Could not create Cloud Build
```

다음 순서로 확인합니다.

1. Firebase 프로젝트가 `fit-mall`인지 확인합니다.
2. 서비스 계정에 Functions 배포 권한이 있는지 확인합니다.
3. Firebase 프로젝트의 결제 플랜과 Cloud Build/API 활성화 상태를 확인합니다.
4. `functions/index.js`의 JavaScript 구문을 확인합니다.
5. Firebase Functions 런타임과 `package.json`의 Node 버전을 확인합니다.

로컬 구문 검사 명령은 다음과 같습니다.

```bash
node --check functions/index.js
```

Cloud Functions 배포는 Rules와 달리 운영 코드와 비용에 직접 영향을 줄 수 있으므로, 새 함수나 트리거를 추가한 경우 먼저 별도 테스트 프로젝트에서 검증하는 것이 좋습니다.

### 2.13 Cloudflare Pages 배포 실패

대표 오류는 다음과 같습니다.

```text
Authentication error
Invalid project name
No such project
The process completed with exit code 1
```

다음 Secret을 확인합니다.

```text
CLOUDFLARE_API_TOKEN
CLOUDFLARE_ACCOUNT_ID
```

워크플로의 프로젝트 이름은 다음과 같습니다.

```yaml
env:
  CF_PROJECT: twofit-mall
```

Cloudflare Dashboard의 Pages 프로젝트 이름과 정확히 일치해야 합니다. API Token에는 Pages 배포 권한이 필요합니다.

로컬에서 Wrangler 인증 상태를 확인하려면 API Token을 출력하지 않고 다음 명령을 사용합니다.

```bash
npx wrangler@3.78.12 pages project list
```

배포 디렉터리도 확인합니다.

```bash
test -f build/web/index.html
npx wrangler@3.78.12 pages deploy build/web --project-name=twofit-mall --branch=main
```

### 2.14 Cloudflare 캐시 purge 실패

캐시 purge는 웹 배포 이후 실행되는 마지막 단계입니다. `CLOUDFLARE_ZONE_ID`가 없으면 워크플로는 purge를 건너뛰도록 구성할 수 있습니다.

대표 오류는 다음과 같습니다.

```text
Invalid zone identifier
Authentication error
API request failed
```

캐시 purge가 실패해도 새 배포 자체가 실패한 것은 아닐 수 있습니다. 먼저 Cloudflare Pages의 배포 URL에서 새 커밋이 보이는지 확인한 뒤, 필요하면 Cloudflare Dashboard에서 캐시를 수동으로 purge합니다.

## 3. GitHub Actions 재실행 방법

일시적인 네트워크 오류나 패키지 저장소 장애라면 다음 순서로 재실행합니다.

1. 실패한 실행 화면에서 **Re-run failed jobs**를 선택합니다.
2. 캐시 문제로 의심되면 `workflow_dispatch`에서 `skip_cache: true`로 실행합니다.
3. 같은 Step에서 반복 실패하면 로컬에서 명령을 재현합니다.
4. Secret 또는 소스 변경이 필요한 경우 수정 후 `main`에 push합니다.

워크플로를 수동 실행할 때는 다음 경로를 사용합니다.

```text
Actions
→ Build & Deploy — Firebase + Cloudflare Pages
→ Run workflow
→ Branch: main
→ skip_cache: true 또는 false
→ Run workflow
```

## 4. 배포 성공처럼 보이지만 운영에 반영되지 않는 경우

### 웹사이트는 이전 화면이 표시됨

다음 항목을 순서대로 확인합니다.

```text
Cloudflare Pages 배포 로그
Cloudflare 배포 커밋 SHA
Cloudflare 캐시 purge 결과
브라우저 강력 새로고침
서비스 워커 unregister 후 재등록
```

Chrome에서는 다음을 사용합니다.

```text
F12 → Application → Storage → Clear site data
F12 → Application → Service Workers → Unregister
Ctrl+Shift+R
```

### Firestore Rules만 반영되지 않음

기존 워크플로는 Rules 배포 실패를 무시하도록 되어 있을 수 있습니다. 최종 워크플로에서는 Firebase 배포 단계에 `continue-on-error: true`를 사용하지 않아야 합니다.

```yaml
- name: Deploy Firestore Rules, Storage Rules, and Cloud Functions
  run: firebase deploy --only firestore:rules,storage,functions --project fit-mall --non-interactive
```

GitHub Actions 로그에 실제로 다음 명령이 실행되었는지 확인합니다.

```text
firebase deploy --only firestore:rules,storage,functions
```

### Storage 파일 업로드가 갑자기 거부됨

이번 보안 수정에서는 다음 경로만 새로 허용합니다.

```text
group_orders/{userId}/{orderId}/...
exchange_requests/{userId}/{requestId}/...
```

클라이언트 코드와 Storage Rules 중 하나만 변경되면 `permission-denied`가 발생합니다. 두 부분이 함께 배포되었는지 확인합니다.

### Functions 인증 요청이 401 또는 403

| 응답 | 의미 | 해결 |
|---:|---|---|
| 401 | ID Token 누락·만료·검증 실패 | `Authorization: Bearer <ID_TOKEN>` 확인 |
| 403 | 인증은 됐지만 관리자 아님 | 사용자 문서 `isAdmin` 또는 Custom Claims 확인 |
| 200 | 관리자 인증 성공 | 요청 데이터와 FCM 토큰 상태 확인 |

ID Token과 서비스 계정 키는 로그나 채팅에 출력하지 않습니다.

## 5. 운영 배포 전 체크리스트

| 확인 | 기준 |
|---|---|
| GitHub 워크플로 | `main` 브랜치의 `.github/workflows/deploy.yml`에 최신 코드 존재 |
| Firebase 프로젝트 | `fit-mall`로 고정 |
| Firebase Secret | `GOOGLE_APPLICATION_CREDENTIALS_JSON` 존재 |
| Cloudflare Secret | API Token과 Account ID 존재 |
| Flutter 분석 | 컴파일 error 0개 |
| 웹 빌드 | `build/web/index.html` 생성 |
| FCM 워커 | 두 서비스 워커 파일 생성 및 통합 코드 확인 |
| Firestore Rules | 실제 컬렉션·소유자 필드와 규칙이 일치 |
| Storage Rules | 새 경로와 클라이언트 업로드 경로가 일치 |
| Functions | `node --check functions/index.js` 통과 |
| 배포 단계 | Firebase 배포가 실패하면 전체 Job이 실패하도록 구성 |
| 운영 확인 | 로그인·상품·주문·관리자·FCM 테스트 완료 |

## 6. 긴급 롤백 기준

배포 직후 로그인, 주문, 관리자 접근, 결제 등 핵심 기능이 작동하지 않으면 추가 배포를 중단합니다. 먼저 어느 구성요소가 문제인지 확인합니다.

| 문제 영역 | 우선 조치 |
|---|---|
| 웹 UI만 문제 | Cloudflare Pages의 이전 배포로 롤백 |
| Firestore 접근 거부 | Firebase Console Rules 기록에서 이전 규칙 복구 |
| Storage 업로드 거부 | 이전 Storage Rules 복구 또는 새 경로 마이그레이션 완료 후 재배포 |
| Functions 오류 | 이전 커밋의 Functions를 재배포 |
| FCM만 문제 | 웹 배포를 되돌리지 말고 서비스 워커·VAPID·권한부터 확인 |

롤백 전에는 현재 배포 커밋 SHA와 실패 로그를 보존합니다. 운영 데이터가 변경된 뒤에는 웹 코드만 이전 버전으로 되돌려도 데이터 구조가 자동으로 복구되지 않으므로, Firestore·Storage 스키마 변경이 있었다면 별도 데이터 복구 계획이 필요합니다.

## 7. 보안 주의사항

서비스 계정 JSON, Firebase ID Token, Cloudflare API Token, 결제 Secret, 네이버 Client Secret은 GitHub Actions 로그에 출력하지 않습니다. Secret이 로그에 노출되었거나 저장소에 커밋되었다면 즉시 폐기·재발급해야 합니다.

또한 운영 배포는 `main` 브랜치 보호 규칙과 Pull Request 리뷰를 적용하는 것이 좋습니다. Rules와 Functions는 웹 정적 파일보다 영향 범위가 크므로, 가능하면 별도 스테이징 Firebase 프로젝트에서 검증한 후 운영에 반영해야 합니다.

## 8. 빠른 진단 명령 모음

```bash
# 프로젝트 및 브랜치 확인
git branch --show-current
git log -1 --oneline

# Flutter 확인
flutter --version
flutter pub get
flutter analyze
flutter build web --release

# 웹 산출물 확인
test -f build/web/index.html
test -f build/web/firebase-messaging-sw.js
test -f build/web/flutter_service_worker.js

# Functions 확인
cd functions
npm ci
node --check index.js
cd ..

# Firebase 설정 확인
firebase use
firebase projects:list

# Rules를 구성요소별로 별도 배포해 실패 지점 확인
firebase deploy --only firestore:rules --project fit-mall
firebase deploy --only storage --project fit-mall
firebase deploy --only functions --project fit-mall

# GitHub Actions에서 재현할 Cloudflare 배포 확인
npx wrangler@3.78.12 pages deploy build/web --project-name=twofit-mall --branch=main
```

이 가이드의 핵심은 **Firebase 배포 실패를 무시하지 않고**, 오류가 해결될 때까지 Cloudflare Pages 배포를 진행하지 않는 것입니다. 그래야 웹 UI와 백엔드 보안 규칙이 서로 다른 버전으로 운영되는 위험을 줄일 수 있습니다.


## 9. Firestore·Storage Rules 자동배포 설정

현재 워크플로는 Flutter 웹 배포 전에 Firebase Rules와 Cloud Functions를 자동 배포하도록 구성되어 있습니다. Rules만 별도로 자동화하려는 경우에도 같은 인증 방식을 사용할 수 있습니다.

### 9.1 Firebase 설정 파일 확인

프로젝트 루트의 `firebase.json`은 다음 세 경로를 연결해야 합니다.

```json
{
  "firestore": {
    "rules": "firestore.rules"
  },
  "storage": {
    "rules": "storage.rules"
  },
  "functions": {
    "source": "functions",
    "runtime": "nodejs20"
  }
}
```

`.firebaserc`의 기본 프로젝트는 운영 프로젝트인 `fit-mall`이어야 합니다.

```json
{
  "projects": {
    "default": "fit-mall"
  }
}
```

워크플로에는 다음 사전 검증 단계가 포함되어 있습니다.

```yaml
- name: Validate Firebase Rules configuration
  shell: bash
  run: |
    set -euo pipefail
    test -f firestore.rules
    test -f storage.rules
    test -f firebase.json
    test -f .firebaserc
    node <<'NODE'
    const fs = require('fs');
    const config = JSON.parse(fs.readFileSync('firebase.json', 'utf8'));
    if (config.firestore?.rules !== 'firestore.rules') {
      throw new Error('Firestore Rules 경로가 잘못되었습니다.');
    }
    if (config.storage?.rules !== 'storage.rules') {
      throw new Error('Storage Rules 경로가 잘못되었습니다.');
    }
    if (config.functions?.source !== 'functions') {
      throw new Error('Functions source 경로가 잘못되었습니다.');
    }
    const project = JSON.parse(fs.readFileSync('.firebaserc', 'utf8'));
    if (project.projects?.default !== 'fit-mall') {
      throw new Error('기본 Firebase 프로젝트가 fit-mall이 아닙니다.');
    }
    NODE
```

### 9.2 Firebase 서비스 계정 준비

운영 Firebase 프로젝트에서 GitHub Actions가 배포할 수 있는 서비스 계정이 필요합니다. Firebase Console 또는 Google Cloud Console에서 `fit-mall` 프로젝트의 서비스 계정을 생성하고, Rules·Storage·Functions 배포에 필요한 최소 권한을 부여합니다.

권한을 설정할 때에는 조직 정책에 따라 다음 역할 또는 이에 준하는 커스텀 역할을 사용합니다.

| 권한 대상 | 필요한 권한 예시 |
|---|---|
| Firebase 프로젝트 확인 | Firebase Project Viewer |
| Firestore Rules | Firebase Rules Admin 또는 Rules 배포 권한 |
| Storage Rules | Storage Admin 또는 Firebase Rules 배포 권한 |
| Cloud Functions | Cloud Functions Admin, Service Account User |
| Cloud Build | Cloud Build Editor 또는 배포에 필요한 최소 권한 |
| Artifact Registry | Artifact Registry 권한이 필요한 경우 해당 권한 추가 |

서비스 계정 JSON 키를 생성하더라도 로컬 파일이나 GitHub 저장소에 커밋하지 않습니다. JSON 전체 내용을 GitHub Secret에 저장하거나, 조직에서 지원한다면 장기 키보다 GitHub OIDC·Workload Identity Federation을 사용합니다.

### 9.3 GitHub Secret 등록

GitHub 저장소에서 다음 위치로 이동합니다.

```text
Settings
→ Secrets and variables
→ Actions
→ New repository secret
```

다음 이름으로 서비스 계정 JSON을 등록합니다.

```text
GOOGLE_APPLICATION_CREDENTIALS_JSON
```

Secret 값에는 서비스 계정 JSON 파일의 전체 내용을 넣습니다. Secret 이름은 워크플로의 이름과 정확히 같아야 합니다. 값에 JSON을 직접 출력하거나 로그로 확인하지 않습니다.

Cloudflare Pages도 같은 워크플로에서 사용하므로 다음 Secret이 필요합니다.

```text
CLOUDFLARE_API_TOKEN
CLOUDFLARE_ACCOUNT_ID
CLOUDFLARE_ZONE_ID
```

`CLOUDFLARE_ZONE_ID`는 캐시 purge가 필요할 때만 사용합니다. `CLOUDFLARE_API_TOKEN`에는 Pages 배포와 캐시 purge에 필요한 최소 권한만 부여합니다.

### 9.4 Rules와 Functions 배포 단계

현재 워크플로의 핵심 배포 단계는 다음과 같은 구조입니다.

```yaml
- name: Authenticate Firebase with service account
  env:
    GOOGLE_APPLICATION_CREDENTIALS_JSON: ${{ secrets.GOOGLE_APPLICATION_CREDENTIALS_JSON }}
  shell: bash
  run: |
    set -euo pipefail
    if [ -z "${GOOGLE_APPLICATION_CREDENTIALS_JSON}" ]; then
      echo "GOOGLE_APPLICATION_CREDENTIALS_JSON Secret이 설정되지 않았습니다."
      exit 1
    fi

    umask 077
    printf '%s' "${GOOGLE_APPLICATION_CREDENTIALS_JSON}" \
      > "${RUNNER_TEMP}/firebase-service-account.json"
    echo "GOOGLE_APPLICATION_CREDENTIALS=${RUNNER_TEMP}/firebase-service-account.json" \
      >> "${GITHUB_ENV}"

- name: Deploy Firestore Rules, Storage Rules, and Cloud Functions
  shell: bash
  run: |
    set -euo pipefail
    firebase deploy \
      --only firestore:rules,storage,functions \
      --project fit-mall \
      --non-interactive

- name: Remove Firebase service account file
  if: always()
  shell: bash
  run: rm -f "${RUNNER_TEMP}/firebase-service-account.json"
```

`set -euo pipefail`을 사용하므로 Rules 또는 Functions 배포가 실패하면 이후 Cloudflare Pages 배포를 실행하지 않습니다. 운영 보안 규칙 배포 오류를 숨기기 위해 `continue-on-error: true`를 사용하지 않아야 합니다.

### 9.5 Rules만 자동배포하는 최소 워크플로

웹 빌드와 Functions 배포를 분리하고 Rules만 자동화하려면 다음과 같이 별도 Job을 만들 수 있습니다.

```yaml
name: Deploy Firebase Rules

on:
  push:
    branches: [main]
    paths:
      - 'firestore.rules'
      - 'storage.rules'
      - 'firebase.json'
      - '.firebaserc'
      - '.github/workflows/firebase-rules.yml'
  workflow_dispatch:

permissions:
  contents: read

jobs:
  deploy-rules:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20.x'

      - name: Install Firebase CLI
        run: npm install --global firebase-tools@latest

      - name: Validate configuration
        run: |
          test -f firestore.rules
          test -f storage.rules
          node -e "const c=require('./firebase.json'); if(c.firestore?.rules!=='firestore.rules'||c.storage?.rules!=='storage.rules') process.exit(1)"
          node -e "const c=require('./.firebaserc'); if(c.projects?.default!=='fit-mall') process.exit(1)"

      - name: Authenticate Firebase
        env:
          GOOGLE_APPLICATION_CREDENTIALS_JSON: ${{ secrets.GOOGLE_APPLICATION_CREDENTIALS_JSON }}
        run: |
          set -euo pipefail
          test -n "${GOOGLE_APPLICATION_CREDENTIALS_JSON}"
          umask 077
          printf '%s' "${GOOGLE_APPLICATION_CREDENTIALS_JSON}" > "${RUNNER_TEMP}/firebase-sa.json"
          echo "GOOGLE_APPLICATION_CREDENTIALS=${RUNNER_TEMP}/firebase-sa.json" >> "${GITHUB_ENV}"

      - name: Deploy Firestore and Storage Rules
        run: |
          set -euo pipefail
          firebase deploy \
            --only firestore:rules,storage \
            --project fit-mall \
            --non-interactive

      - name: Cleanup credentials
        if: always()
        run: rm -f "${RUNNER_TEMP}/firebase-sa.json"
```

`paths` 필터를 사용하면 Rules 관련 파일이 변경된 경우에만 해당 Workflow가 실행됩니다. 반대로 모든 `main` push마다 Rules를 배포하려면 `paths` 항목을 제거합니다.

### 9.6 배포 성공 확인

GitHub Actions 로그에서 다음 단계가 모두 성공했는지 확인합니다.

```text
Validate Firebase Rules configuration
Authenticate Firebase with service account
Deploy Firestore Rules, Storage Rules, and Cloud Functions
Remove Firebase service account file
```

Firebase Console에서도 다음을 확인합니다.

| 확인 위치 | 확인 내용 |
|---|---|
| Firestore → Rules | 최신 게시 시각과 커밋 반영 여부 |
| Storage → Rules | 최신 Storage Rules 게시 여부 |
| Functions | Functions 배포 시각과 런타임 상태 |
| Cloudflare Pages | 같은 GitHub 커밋의 웹 배포 여부 |

Rules 배포 성공과 실제 권한 동작은 별개이므로, 일반 사용자·관리자 계정으로 읽기·쓰기 권한 테스트를 수행해야 합니다.

### 9.7 Rules 자동배포 실패 대응

| 오류 | 원인 | 조치 |
|---|---|---|
| Secret이 없음 | `GOOGLE_APPLICATION_CREDENTIALS_JSON` 미등록 | Repository secrets에 정확한 이름으로 등록 |
| 인증 실패 | JSON 손상·서비스 계정 만료·권한 부족 | Secret 값을 교체하고 IAM 권한 확인 |
| Firestore Rules 컴파일 오류 | Rules 문법 또는 필드 경로 오류 | 오류 행을 수정한 뒤 다시 push |
| Storage Rules 컴파일 오류 | `firestore.get()` 경로·wildcard·타입 오류 | Storage Rules를 별도 배포해 오류 범위 축소 |
| `PERMISSION_DENIED` | 배포 서비스 계정 권한 부족 | Firebase·Google Cloud IAM 권한 확인 |
| `continue-on-error` 없음 | 의도된 fail-closed 동작 | 오류 해결 후 Job 재실행 |
| 배포는 성공했지만 앱 쓰기 실패 | 실제 데이터 구조와 Rules 불일치 | Emulator 또는 테스트 계정으로 권한 테스트 |

## 10. 적용 순서

먼저 `.github/workflows/deploy.yml`을 GitHub에 반영합니다. 다음으로 `GOOGLE_APPLICATION_CREDENTIALS_JSON`과 Cloudflare Secret을 등록합니다. 이후 Pull Request에서 YAML과 Rules를 검토한 다음 `main`에 merge합니다.

```bash
git add .github/workflows/deploy.yml GITHUB_ACTIONS_TROUBLESHOOTING.md
git commit -m "Automate Firebase Firestore and Storage Rules deployment"
git push origin main
```

GitHub Actions의 첫 실행에서 Firebase 배포 단계가 성공하는지 확인한 뒤, Firebase Console의 Rules 게시 시각과 Cloudflare Pages의 배포 커밋을 비교합니다. 운영 배포 전에는 테스트 계정으로 관리자·일반 사용자 권한을 모두 검증해야 합니다.
