# 관리자 감사 로그 스키마

컬렉션: `admin_audit_logs`

감사 로그는 관리자 화면에서 발생한 민감 작업을 추적하기 위한 append-only 문서입니다. Firestore 규칙상 관리자만 읽거나 생성할 수 있으며 수정·삭제는 차단합니다.

## 공통 필드

| 필드 | 타입 | 설명 |
|---|---|---|
| `schemaVersion` | number | 현재 `1` |
| `action` | string | 작업 식별자. 애플리케이션에서 고정 문자열로 사용 |
| `targetType` | string | `user_profile`, `user_admin_claim`, `order`, `unknown` 등 대상 유형 |
| `targetId` | string | UID, 주문번호 또는 대상 문서 ID |
| `actorUid` | string | 작업을 실행한 관리자 UID |
| `actorEmail` | string 또는 null | 작업자 이메일. 이메일이 없는 계정은 null 가능 |
| `source` | string | 현재 앱 화면에서 기록하는 경우 `admin_app` |
| `details` | map | 작업별 부가 정보. 민감한 비밀번호·토큰은 저장하지 않음 |
| `createdAt` | timestamp | `FieldValue.serverTimestamp()` |

## 현재 action

- `member_profile_deleted`: Firebase Auth 계정이나 주문·결제 기록을 삭제하지 않고 `users/{uid}` 프로필 문서만 삭제
- `staff_admin_granted`: 대상 사용자에게 관리자 Custom Claim 부여
- `staff_admin_revoked`: 대상 사용자에게서 관리자 Custom Claim 해제
- `staff_role_changed`: 관리자 직급 변경
- `group_order_pdf_generation`: 단체주문 PDF 생성 성공·실패 기록

## 조회 기능

관리자 화면의 **감사 로그** 탭에서 다음 기능을 제공합니다.

- 최신 `createdAt` 순 조회
- 30건 단위 페이지네이션
- action 필터
- action, 대상 ID, 관리자 UID·이메일 검색
- 로그 상세의 원본 JSON 확인
- 새로고침 및 다음 페이지 불러오기

감사 로그 기록 실패가 주문서 PDF 생성 등 원래 작업의 성공·실패를 덮어쓰지 않도록 기록 함수는 호출부에서 별도로 처리합니다.
