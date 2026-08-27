# GOOGLE_APPLICATION_CREDENTIALS_JSON 등록 안내

## 1. 준비 사항

필요한 것은 다음 세 가지입니다.

| 항목 | 값 |
|---|---|
| GitHub 저장소 | `chw243527-ux/2fit-mall` |
| Firebase 프로젝트 | `fit-mall` |
| GitHub Secret 이름 | `GOOGLE_APPLICATION_CREDENTIALS_JSON` |

이 Secret은 GitHub Actions가 Firestore Rules, Storage Rules, Cloud Functions를 Firebase 운영 프로젝트에 배포할 때 사용하는 서비스 계정 인증 정보입니다.

> 서비스 계정 JSON은 비밀번호와 같은 민감정보입니다. 채팅, 이메일, GitHub 일반 파일, 커밋 기록, 스크린샷에 공개하지 않습니다.

## 2. Firebase 서비스 계정 JSON 생성

[Firebase Console](https://console.firebase.google.com/)에 운영 Firebase 프로젝트에 접근 권한이 있는 Google 계정으로 로그인합니다.

다음 순서로 이동합니다.

```text
Firebase Console
→ fit-mall 프로젝트 선택
→ Project settings
→ Service accounts
→ Firebase Admin SDK
→ Generate new private key
```

확인 창에서 키를 생성하면 JSON 파일이 다운로드됩니다. 파일명은 일반적으로 다음과 비슷합니다.

```text
fit-mall-firebase-adminsdk-xxxxx.json
```

다운로드한 파일을 안전한 로컬 폴더에 보관합니다. 등록이 끝난 뒤에는 필요하지 않은 복사본을 삭제합니다.

### 권한 안내

가장 빠른 방법은 Firebase가 제공하는 프로젝트 서비스 계정을 사용하는 것입니다. 조직 보안정책이 있다면 서비스 계정에 프로젝트 전체 Editor 권한을 부여하기보다 Rules·Functions·Cloud Build·Service Account User에 필요한 최소 권한만 부여합니다.

운영 배포가 계속 `Permission denied`로 실패하면 Firebase 프로젝트의 IAM 화면에서 서비스 계정에 필요한 배포 권한이 있는지 확인합니다.

## 3. JSON 파일 형식 확인

JSON 파일이 손상되지 않았는지 로컬에서 확인합니다. 이 명령은 JSON 내용을 출력하지 않습니다.

### macOS/Linux

```bash
python3 -m json.tool fit-mall-firebase-adminsdk-xxxxx.json >/dev/null \
  && echo "JSON 형식 정상"
```

### Windows PowerShell

```powershell
Get-Content .\fit-mall-firebase-adminsdk-xxxxx.json -Raw | ConvertFrom-Json | Out-Null
Write-Host "JSON 형식 정상"
```

JSON 파일에는 일반적으로 다음 필드가 있어야 합니다.

```text
type
project_id
private_key_id
private_key
client_email
client_id
```

`project_id`가 `fit-mall`인지 확인합니다. `private_key`의 줄바꿈이 실제 JSON 안에서 `\n`으로 유지되어야 하며, 내용을 임의로 수정하지 않습니다.

## 4. GitHub 웹 화면에서 Secret 등록

[2FIT MALL GitHub 저장소](https://github.com/chw243527-ux/2fit-mall)를 열고 다음 메뉴로 이동합니다.

```text
Settings
→ Secrets and variables
→ Actions
→ Secrets 탭
→ New repository secret
```

다음처럼 입력합니다.

| 입력란 | 입력값 |
|---|---|
| Name | `GOOGLE_APPLICATION_CREDENTIALS_JSON` |
| Secret | 서비스 계정 JSON 파일 전체 내용 |

JSON 파일을 메모장 또는 VS Code로 열어 `{`부터 `}`까지 전체 내용을 복사해 Secret 입력창에 붙여 넣습니다. 공백과 줄바꿈은 그대로 두어도 됩니다.

마지막으로 **Add secret**을 선택합니다. 저장 후 Secret 값이 별표로 표시되거나 다시 볼 수 없는 것이 정상입니다.

### 반드시 Repository secret으로 등록

이번 워크플로는 다음 표현을 사용합니다.

```yaml
${{ secrets.GOOGLE_APPLICATION_CREDENTIALS_JSON }}
```

따라서 `Repository secrets`에 등록해야 합니다. `Environment secrets`에 등록할 경우 워크플로 Job에 해당 Environment가 지정되어 있지 않으면 Secret이 전달되지 않습니다.

## 5. GitHub CLI로 등록하는 방법

GitHub CLI를 사용한다면 JSON 내용을 터미널에 출력하지 않고 파일에서 직접 Secret으로 보낼 수 있습니다.

먼저 GitHub CLI에 로그인합니다.

```bash
gh auth login
```

그 다음 저장소를 지정해 Secret을 등록합니다.

### macOS/Linux

```bash
gh secret set GOOGLE_APPLICATION_CREDENTIALS_JSON \
  --repo chw243527-ux/2fit-mall \
  < fit-mall-firebase-adminsdk-xxxxx.json
```

### Windows PowerShell

```powershell
Get-Content .\fit-mall-firebase-adminsdk-xxxxx.json -Raw |
  gh secret set GOOGLE_APPLICATION_CREDENTIALS_JSON `
    --repo chw243527-ux/2fit-mall
```

등록된 Secret의 존재 여부만 확인하려면 다음을 실행합니다. 실제 값은 출력되지 않습니다.

```bash
gh secret list --repo chw243527-ux/2fit-mall
```

목록에 다음 이름이 표시되어야 합니다.

```text
GOOGLE_APPLICATION_CREDENTIALS_JSON
```

## 6. 워크플로 파일 확인

GitHub의 `.github/workflows/deploy.yml`에 다음 세 부분이 있어야 합니다.

### Secret을 임시 파일로 저장

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
```

### Rules·Functions 배포

```yaml
- name: Deploy Firestore Rules, Storage Rules, and Cloud Functions
  shell: bash
  run: |
    set -euo pipefail
    firebase deploy \
      --only firestore:rules,storage,functions \
      --project fit-mall \
      --non-interactive
```

### 임시 인증 파일 삭제

```yaml
- name: Remove Firebase service account file
  if: always()
  shell: bash
  run: rm -f "${RUNNER_TEMP}/firebase-service-account.json"
```

`if: always()`가 있어 배포 실패 시에도 임시 JSON 파일이 삭제됩니다. Secret 값 자체를 `echo`로 출력하는 코드는 넣지 않습니다.

## 7. 자동배포 실행

Secret 등록과 워크플로 반영이 끝나면 `main` 브랜치에 변경을 push합니다.

```bash
git add .github/workflows/deploy.yml firestore.rules storage.rules functions/
git commit -m "Automate Firebase Rules and Functions deployment"
git push origin main
```

또는 GitHub에서 다음 메뉴로 수동 실행할 수 있습니다.

```text
Actions
→ Build & Deploy — Firebase + Cloudflare Pages
→ Run workflow
→ Branch: main
→ Run workflow
```

캐시가 의심되면 `skip_cache`를 `true`로 선택합니다.

## 8. 성공 여부 확인

GitHub Actions에서 다음 단계가 초록색인지 확인합니다.

```text
Validate Firebase Rules configuration
Authenticate Firebase with service account
Install Cloud Functions dependencies
Deploy Firestore Rules, Storage Rules, and Cloud Functions
Deploy Flutter Web to Cloudflare Pages
```

Firebase Console에서도 다음을 확인합니다.

```text
Firestore Database → Rules → 최신 게시 시각
Storage → Rules → 최신 게시 시각
Build → Functions → 최신 배포 시각
```

## 9. 오류별 해결

| 오류 | 원인 | 해결 |
|---|---|---|
| `GOOGLE_APPLICATION_CREDENTIALS_JSON Secret이 설정되지 않았습니다` | Secret 미등록·이름 오타·잘못된 저장 위치 | Repository secret에 정확한 이름으로 등록 |
| `Failed to authenticate` | JSON 손상·잘못된 프로젝트·키 폐기 | JSON을 다시 생성하고 Secret 교체 |
| `Permission denied` | 서비스 계정 IAM 권한 부족 | Firebase·Google Cloud IAM 권한 확인 |
| `Project not found` | `.firebaserc` 또는 배포 프로젝트 불일치 | `fit-mall` 프로젝트와 Secret의 `project_id` 확인 |
| `Compilation error in firestore.rules` | Firestore Rules 문법·필드 경로 오류 | 오류 행을 수정한 뒤 재실행 |
| `Compilation error in storage.rules` | Storage Rules 문법·경로 오류 | `storage.rules`와 클라이언트 업로드 경로 비교 |
| Functions 배포 중 결제 플랜 오류 | Cloud Functions 배포 조건 미충족 | Firebase 프로젝트 요금제·API 활성화 확인 |
| Secret은 있는데 빈 값으로 인식 | Environment secret에 잘못 등록 | Repository secrets로 이동하거나 Job Environment 설정 |

## 10. 키가 노출된 경우

서비스 계정 JSON이 GitHub 커밋, Actions 로그, 채팅, 공개 저장소 또는 스크린샷에 노출되었다면 즉시 다음 순서로 처리합니다.

```text
1. Google Cloud IAM에서 해당 서비스 계정 키 폐기
2. 새 서비스 계정 키 생성
3. GitHub Secret 값 교체
4. GitHub 저장소와 Actions 로그에서 노출 흔적 확인
5. 필요하면 Git 히스토리에서 민감정보 제거
```

파일을 저장소에서 삭제하는 것만으로는 Git 기록에 남은 키가 무효화되지 않습니다. 키는 반드시 폐기·재발급해야 합니다.

## 11. 최종 체크리스트

| 확인 | 상태 기준 |
|---|---|
| Firebase 프로젝트 | `fit-mall` |
| JSON `project_id` | `fit-mall` |
| GitHub Secret 위치 | Repository secrets |
| GitHub Secret 이름 | `GOOGLE_APPLICATION_CREDENTIALS_JSON` |
| Secret 값 형식 | JSON 전체 내용, Base64 변환하지 않음 |
| 워크플로 인증 | `GOOGLE_APPLICATION_CREDENTIALS` 환경변수 설정 |
| 배포 명령 | `--only firestore:rules,storage,functions` |
| 실패 처리 | Firebase 배포 실패 시 웹 배포 중단 |
| 인증 파일 삭제 | `if: always()` cleanup 단계 존재 |
| 운영 확인 | Rules 게시 시각·Functions 배포 시각·웹 배포 커밋 확인 |
