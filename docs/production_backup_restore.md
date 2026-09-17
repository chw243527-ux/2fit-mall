# 2FIT Mall 운영 백업·복구 절차

## 목적

운영 주문, 상품, 재고 및 첨부파일을 장애나 실수로부터 복구할 수 있도록 백업 범위와 복구 절차를 고정한다. 백업 명령은 운영 프로젝트와 별도의 보호된 버킷을 사용해야 하며, 서비스 계정 키를 저장소에 기록하지 않는다.

## 백업 정책

Firestore는 최소 하루 한 번 자동 내보내기를 수행하고 30일 이상 보존한다. Storage는 객체 버전 관리 또는 별도 백업 버킷을 사용하고, 주문 첨부파일은 최소 30일 이상 보존한다. 백업 버킷은 애플리케이션 서비스 계정의 일반 쓰기 권한과 분리한다.

## Firestore 백업 예시

`gcloud` 인증이 된 운영 담당자 환경에서 실행한다.

```bash
PROJECT_ID=fit-mall
BACKUP_BUCKET=gs://REPLACE_WITH_PROTECTED_BACKUP_BUCKET
DATE=$(date -u +%Y%m%dT%H%M%SZ)
gcloud firestore export "$BACKUP_BUCKET/firestore/$DATE" \
  --project "$PROJECT_ID" \
  --async
```

백업 실행 후 `gcloud firestore operations list --project fit-mall`로 완료 여부를 확인하고, 보호된 버킷의 객체 보존 정책과 접근 로그를 확인한다.

## 복구 예시

복구는 사용자에게 영향을 주므로 승인된 유지보수 창에서 수행한다. 먼저 별도 테스트 프로젝트에 복구하여 주문·재고·사용자 문서를 검증한다.

```bash
gcloud firestore import gs://REPLACE_WITH_PROTECTED_BACKUP_BUCKET/firestore/REPLACE_WITH_EXPORT_ID \
  --project fit-mall \
  --async
```

복구 후 관리자 대시보드, 주문 조회, 상품 재고, 첨부파일 접근을 확인한다. 운영 데이터에 대한 덮어쓰기 복구는 반드시 변경 승인과 복구 전 스냅샷 생성 후 수행한다.

## 배포 전 확인

운영 담당자는 다음을 확인한다.

- 보호된 백업 버킷이 존재한다.
- Firestore export가 최근 24시간 안에 성공했다.
- Storage 객체 버전 관리 또는 별도 복제가 활성화되어 있다.
- 복구 테스트 프로젝트와 담당자가 지정되어 있다.
- 최근 안정 커밋 `292582f`와 이전 안정 커밋을 롤백 대상으로 기록했다.
- 백업 명령 결과와 복구 검증 결과를 운영 기록에 남긴다.

> 이 문서는 백업을 자동으로 수행했다고 의미하지 않는다. 실제 백업 버킷, 보존 정책, IAM 권한 및 복구 테스트는 Firebase/GCP 운영 계정에서 확인해야 한다.
