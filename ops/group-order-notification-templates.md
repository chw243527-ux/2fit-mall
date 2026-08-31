# 단체주문 고객 알림 템플릿

## 적용 범위

`orders/{orderId}` 문서가 생성되고 `orderType`이 `group` 또는 `additional`인 경우에만 고객 알림을 처리한다. 일반 상품 주문에는 이 알림을 발송하지 않는다.

## 카카오 알림톡 승인용 템플릿

**템플릿명:** 2FIT MALL 단체주문 접수 완료

**본문:**

안녕하세요, #{고객명}님.

2FIT MALL 단체주문 신청이 접수되었습니다.

- 주문번호: #{주문번호}
- 팀명: #{팀명}
- 상품: #{상품명}
- 수량: #{수량}
- 접수일시: #{접수일시}

담당자가 주문 내용을 확인한 후 디자인·견적 및 진행 일정을 안내드리겠습니다.
문의사항은 2FIT MALL 고객센터로 문의해 주세요.

감사합니다.

**사용 변수:** `#{고객명}`, `#{주문번호}`, `#{팀명}`, `#{상품명}`, `#{수량}`, `#{접수일시}`

카카오 검수 승인 후 발급되는 템플릿 ID를 Firebase Functions 파라미터 `KAKAO_GROUP_ORDER_TEMPLATE_ID`에 등록한다. 승인되지 않은 템플릿 ID가 비어 있으면 알림톡은 발송하지 않고 `skipped_template_not_configured`로 기록한다.

## 이메일 템플릿

**제목:** `[2FIT MALL] 단체주문 접수 완료 (주문번호)`

이메일에는 고객명, 주문번호, 팀명, 상품명, 수량, 예상 금액과 담당자 확인 안내를 포함한다. 전화번호·주소·디자인 원문·로고 파일의 URL은 고객 알림 본문과 발송 로그에 포함하지 않는다.

HTML 템플릿은 `functions/index.js`의 `_groupOrderReceiptEmailHtml`에서 생성하며, 사용자 입력값은 HTML escape 처리한다. Resend 발신 도메인 인증이 완료된 뒤에만 운영 발송을 활성화한다.

## Firebase 설정

```bash
firebase functions:secrets:set RESEND_API_KEY
firebase functions:params:set KAKAO_GROUP_ORDER_TEMPLATE_ID=승인된_템플릿_ID
firebase functions:params:set RESEND_FROM_EMAIL='2FIT MALL <no-reply@2fit-mall.co.kr>'
```

SOLAPI의 기존 `SOLAPI_API_KEY`, `SOLAPI_API_SECRET`도 Functions Secret으로 등록되어 있어야 한다. 비밀값은 저장소·클라이언트 코드·Firestore 문서에 저장하지 않는다.

## 발송 및 중복 방지

발송 결과는 주문 하위의 `notification_deliveries/group_order_receipt` 문서에 저장한다. 원문 이메일과 전화번호는 저장하지 않는다. 동일 이벤트의 재실행은 `sent` 상태에서 건너뛰며, 처리 중 상태가 10분 이상 지속되면 재시도한다. 두 채널이 모두 설정되지 않은 경우 주문 저장 자체는 실패시키지 않고 발송 결과를 `failed` 또는 `skipped_*`로 기록한다.

## 운영 전 확인

카카오 알림톡 템플릿은 카카오 검수를 통과해야 하며, Resend 발신 도메인의 SPF·DKIM 설정과 수신 테스트를 완료해야 한다. 테스트 주문으로 이메일 수신, 알림톡 수신, 중복 미발송, 잘못된 전화번호·이메일의 건너뜀, 발송 실패 기록을 확인한 뒤 운영 활성화한다.

발송 기능은 고객 입력값을 클라이언트에서 직접 신뢰하지 않고 주문 생성 이벤트에서 서버가 읽어 처리한다.

## 참고

- [Resend API 문서](https://resend.com/docs/api-reference/emails/send-email)
- [SOLAPI 메시지 API 문서](https://developers.solapi.com/references/messages/v4/send)
- [Firebase Cloud Functions Firestore 트리거 문서](https://firebase.google.com/docs/functions/firestore-events)

## References

[1]: https://resend.com/docs/api-reference/emails/send-email "Resend Send Email API"
[2]: https://developers.solapi.com/references/messages/v4/send "SOLAPI Messages API"
[3]: https://firebase.google.com/docs/functions/firestore-events "Firebase Firestore Events"

*작성자: Manus AI*

*작성일: 2026-08-31*

*상태: 코드 템플릿 구현 완료, 외부 사업자 승인·Secret 등록 후 운영 발송 가능*

이 문서는 코드 설정과 운영 절차를 설명하기 위한 자료이며, 외부 서비스의 실제 승인 상태는 각 서비스 콘솔에서 별도로 확인해야 한다.

---

## 운영 발송 상태 해석

| 상태 | 의미 |
|---|---|
| `sent` | 해당 채널의 발송 API가 성공 응답을 반환함 |
| `failed_<HTTP 상태코드>` | 발송 API가 오류 응답을 반환함 |
| `skipped_template_not_configured` | 알림톡 템플릿 ID가 등록되지 않음 |
| `skipped_invalid_phone` | 전화번호 형식이 유효하지 않음 |
| `skipped_invalid_email` | 이메일 형식이 유효하지 않음 |
| `skipped_no_email` | 주문에 이메일이 없음 |

알림톡과 이메일 모두 `sent`가 되지 않으면 주문 문서의 하위 발송 기록 상태는 `failed`로 남고, 주문 접수 자체는 유지된다.

> 단체주문 접수 알림은 주문 접수 안내용이며, 결제 완료·배송 시작·환불 확정 통지를 의미하지 않는다.

## 변경 이력

| 일자 | 내용 |
|---|---|
| 2026-08-31 | 단체주문 접수 시 SOLAPI 알림톡·Resend 이메일 자동 발송 구조와 중복 방지 기록 추가 |

## 개인정보 보호 주의

CI·DI, 비밀번호, 인증 토큰, 전체 주소, 디자인 원문 파일은 이 템플릿에서 수집하거나 발송하지 않는다. 알림 본문에는 고객이 접수 사실과 주문번호를 확인하는 데 필요한 최소 정보만 포함한다.

## 연락처 자리표시자

실제 고객센터 전화번호와 상담 URL을 카카오 승인 문안에 넣을 경우, 운영 확정값으로 치환한 뒤 카카오 템플릿을 재검수한다. 승인 전 문안과 운영 문안이 달라지면 알림톡 발송이 거절될 수 있다.

## 구현 파일

- `functions/index.js`: 주문 생성 트리거, 발송 함수, HTML escape, 중복 방지 기록
- `functions/package.json`: Node 22 및 기본 Firebase Functions 의존성
- `ops/group-order-notification-templates.md`: 본 문서

## 배포 전 명령 예시

```bash
cd functions && npm ci && npm test
cd ..
firebase functions:secrets:set RESEND_API_KEY
firebase functions:params:set KAKAO_GROUP_ORDER_TEMPLATE_ID=승인된_템플릿_ID
firebase deploy --only functions
```

운영 배포 전에 테스트 주문을 1건 생성하여 발송 기록과 실제 수신함을 함께 확인한다.

## 참고 범위

이 구현은 고객에게 접수 완료 알림을 보내는 기능이다. 카카오 알림톡 템플릿 심사, Resend 도메인 인증, 발신번호·채널 등록, 수신거부·광고성 메시지 분류는 외부 사업자 정책과 운영 설정에 따라 별도 완료해야 한다.

## 최종 판단

코드 기반은 준비되었지만, 외부 Secret·카카오 승인 템플릿·Resend 도메인 인증이 등록되기 전에는 실제 운영 발송이 활성화되지 않는다.

*End of document.*

[Resend Send Email API]: https://resend.com/docs/api-reference/emails/send-email
[SOLAPI Messages API]: https://developers.solapi.com/references/messages/v4/send
[Firebase Firestore Events]: https://firebase.google.com/docs/functions/firestore-events

> 운영 테스트에서 고객의 실제 개인정보를 사용하지 말고, 별도 테스트 수신번호·테스트 이메일을 사용한다.

### 알림 발송 범위

| 채널 | 자동 발송 시점 | 고객 대상 |
|---|---|---|
| 카카오 알림톡 | 단체주문 Firestore 문서 생성 후 | `userPhone` 또는 주문서의 `customOptions.phone` |
| 이메일 | 단체주문 Firestore 문서 생성 후 | `userEmail` 또는 주문서의 `customOptions.email` |

### 실패 시 처리

발송 실패가 주문 접수 실패로 전파되지 않도록 알림 처리 오류를 격리한다. 관리자는 Firestore 하위 발송 기록에서 채널별 상태를 확인하고, 원인 해결 후 실패 이벤트를 재실행할 수 있다.

### 검증 체크리스트

- [ ] 카카오 승인 템플릿의 변수명이 코드와 일치한다.
- [ ] SOLAPI 발신번호와 카카오 채널 연결 상태를 확인했다.
- [ ] Resend 발신 도메인의 SPF·DKIM을 확인했다.
- [ ] 테스트 주문에서 두 채널의 수신을 확인했다.
- [ ] 동일 주문 이벤트 재실행 시 중복 발송되지 않았다.
- [ ] 잘못된 연락처는 건너뛰고 주문은 정상 접수되었다.
- [ ] 발송 로그에 전화번호·이메일 원문이 남지 않았다.
- [ ] Secrets와 발신 설정이 클라이언트 번들에 포함되지 않았다.

*고객 알림 문구의 실제 법적·광고성 분류는 운영자가 발송 목적과 관련 법령에 따라 최종 확인해야 한다.*

[END]

