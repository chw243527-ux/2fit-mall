# Google Play 자동 업로드 설정

이 저장소는 `main` 브랜치에 Android 관련 변경이 push되면 서명된 Android App Bundle을 빌드하고 Google Play Console의 내부 테스트 트랙에 업로드하도록 구성되어 있습니다.

## 필요한 Google Play 설정

Google Cloud에서 Google Play Developer API를 활성화하고 서비스 계정을 만든 뒤, 서비스 계정 이메일을 Play Console의 **설정 → API 액세스 → 사용자 및 권한**에 초대해야 합니다. 앱에 대해 최소한 다음 권한을 부여합니다.

| 권한 | 용도 |
|---|---|
| 앱 정보 보기 및 다운로드 | 패키지와 트랙 상태 확인 |
| 테스트 트랙 관리 | 내부 테스트 릴리스 업로드 |
| 앱 버전 생성·수정 | 새 AAB 릴리스 생성 |

서비스 계정 JSON 키는 저장소 파일에 커밋하지 말고 GitHub 저장소의 **Settings → Secrets and variables → Actions**에 다음 이름으로 등록합니다.

| Secret | 값 |
|---|---|
| `GOOGLE_PLAY_SERVICE_ACCOUNT_JSON` | 서비스 계정 JSON 전체 내용 |
| `ANDROID_KEYSTORE_BASE64` | 현재 Play 앱 서명에 사용하는 upload keystore를 base64로 인코딩한 값 |
| `ANDROID_KEYSTORE_PASSWORD` | keystore 비밀번호 |
| `ANDROID_KEY_ALIAS` | key alias |
| `ANDROID_KEY_PASSWORD` | key 비밀번호 |

기존 서명 키와 다른 키를 사용하면 Google Play에서 업데이트로 인정하지 않으므로, 반드시 현재 Play Console 앱에 연결된 upload key를 사용해야 합니다.

## 동작 방식

`.github/workflows/android-play-internal.yml`은 `main` push 또는 수동 실행으로 동작합니다. 빌드 번호는 `1000 + GitHub Actions 실행 번호`로 계산해 이미 사용된 versionCode와 충돌하지 않도록 합니다. 기본 업로드 트랙은 `internal`이며, 수동 실행 시 `closed` 트랙도 선택할 수 있습니다.

웹 배포는 기존처럼 `main` push 후 Cloudflare Pages에 자동 배포됩니다. Android 자동 업로드가 성공하면 Play Console 내부 테스트 트랙에 새 릴리스가 생성되지만, Google Play의 테스터 배포·검토·사용자 업데이트 시점은 Play Console 정책에 따라 별도로 처리됩니다.

## 안전한 운영 순서

처음에는 `main` push 자동 업로드를 내부 테스트 트랙에서만 사용합니다. 서비스 계정 권한과 서명 키가 검증된 후에만 closed 또는 production 트랙으로 확장해야 합니다. production 자동 배포는 실수로 운영 사용자에게 즉시 배포될 위험이 있으므로 별도의 release tag와 승인 절차를 두는 것을 권장합니다.
