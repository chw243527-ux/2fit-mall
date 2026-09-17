# 2FIT Mall 보안 자동 검증

`security_audit.sh`는 배포 전 보안 게이트에서 자동화할 수 있는 검사를 읽기 전용으로 실행합니다.

## 실행

저장소 루트에서 다음 명령을 실행합니다.

```bash
security/security_audit.sh
```

로컬에 Flutter·Firebase CLI가 없을 때도 정적 검사는 실행됩니다. 모든 선택 도구를 반드시 요구하려면 다음처럼 실행합니다.

```bash
security/security_audit.sh --strict
```

의존성 감사가 불가능한 환경에서는 다음 옵션으로 정적 검사만 실행할 수 있습니다.

```bash
security/security_audit.sh --skip-dependency-audit
```

## 자동 검사 범위

| 영역 | 검사 내용 |
|---|---|
| 저장소 | 필수 보안 파일과 lockfile 존재 여부, 추적된 고위험 비밀정보 패턴 |
| Firebase Rules | 관리자 custom claim 기본값, 주문 소유권 경계, Storage 업로드 크기·MIME 제한, 소유자 없는 레거시 경로 차단 |
| Cloud Functions | JavaScript 문법, 관리자 인증·결제 검증·만료·금액 검증 관련 보안 마커 |
| 의존성 | Functions `npm audit`와 Flutter 의존성 메타데이터 확인 |
| 프로젝트 품질 | Flutter 정적 분석, Firebase CLI 설치 여부 확인 |

## CI

`.github/workflows/security-audit.yml`이 Pull Request와 `main` 브랜치 push에서 자동 실행합니다. CI에서는 `npm ci --ignore-scripts` 후 스크립트를 실행하므로 Functions 의존성 감사도 포함됩니다.

## 자동화하지 않는 항목

실제 결제 승인·취소·중복 호출, 실제 FCM 수신, Firestore/Storage Rules의 사용자별 허용·거부 시나리오, 모바일·태블릿 레이아웃, 백업 복구, 운영 도메인 CORS 동작은 운영 데이터와 인증 계정이 필요합니다. 이 항목들은 `production_final_qa_checklist.md`의 수동 검수로 남겨야 하며, 자동 게이트 통과만으로 운영 출시를 승인해서는 안 됩니다.

## 종료 코드

- `0`: 자동 검사 실패 없음. 경고가 있을 수 있음.
- `1`: 하나 이상의 차단 검사 실패.
- `2`: 잘못된 옵션 또는 사용법 오류.

비밀정보 탐지에 걸린 경우 값 자체는 출력하지 않고 실패만 표시합니다. 실제 확인은 해당 파일의 변경 이력과 Secret Manager 설정을 별도로 점검해야 합니다.
