# 2FIT Mall 프로덕션 운영 모니터링

## 구성

`Production Monitor` GitHub Actions가 **6시간마다** 자동 실행되며, 운영 웹의 가용성과 기본 보안 상태를 점검한다. 수동 실행은 GitHub Actions의 `Production Monitor`에서 `Run workflow`를 선택해 수행할 수 있다.

모니터는 HTTPS 응답 코드, 전체 응답시간, HTML 응답 여부, HSTS, `X-Content-Type-Options`, `X-Frame-Options`, `Referrer-Policy`, `Permissions-Policy`, TLS 인증서 만료 임박 여부를 확인한다. 응답시간이 3초를 초과하거나 하나라도 필수 검사가 실패하면 실행이 실패한다.

## 대시보드 확인

각 실행의 **Summary** 탭에 표 형태의 상태 대시보드가 생성된다. 원본 헤더, 응답 HTML, JSON 상태 파일은 실행 Artifact에 30일 동안 보관된다. 실행 이력은 다음에서 확인한다.

[Production Monitor 실행 이력](https://github.com/chw243527-ux/2fit-mall/actions/workflows/production-monitor.yml)

## 알림 동작

모니터링 실패 시 워크플로가 실패하고 `production,monitoring` 라벨의 GitHub Issue를 생성한다. 동일한 미해결 알림 Issue가 있으면 새 Issue를 만들지 않고 기존 Issue에 실행 결과를 댓글로 추가한다. Issue 생성 권한이 제한된 실행에서도 워크플로 Summary와 Artifact는 남는다.

GitHub 사용자 알림을 받으려면 저장소의 Watch 설정에서 Actions 또는 All Activity 알림을 활성화한다. Slack, 이메일, SMS 또는 카카오 알림은 별도의 Webhook/API 비밀값과 수신자 설정이 필요하므로 현재 자동 연결하지 않았다. 연결할 경우 저장소 Settings → Secrets and variables → Actions에 `MONITOR_ALERT_WEBHOOK`을 추가하고, 조직 보안정책에 맞는 전송 함수를 워크플로에 연결한다. 비밀값은 코드나 로그에 기록하지 않는다.

## 운영 임계치

| 항목 | 현재 기준 | 대응 |
|---|---:|---|
| HTTP 응답 | 2xx 또는 3xx | 실패 시 배포·호스팅 상태 확인 |
| 전체 응답시간 | 3초 이하 | CDN, Firebase Hosting, 번들 크기 확인 |
| TLS 인증서 | 14일 이상 남음 | 인증서 갱신 확인 |
| 보안 헤더 | 5개 필수 헤더 | Hosting/Cloudflare 헤더 설정 확인 |
| 연속 실패 | 2회 이상 | 운영 장애로 분류하고 로그·Functions·Firebase 상태 확인 |

## 범위와 한계

이 모니터는 공개 웹의 가용성·보안 헤더·TLS를 확인하는 합성 모니터다. 실제 로그인, Toss 결제 승인, Firestore 재고 변경, FCM 수신 여부를 자동으로 검증하지 않는다. 결제와 재고는 테스트 계정·테스트 상품을 사용하는 별도 운영 QA를 수행해야 하며, 자동화 시에는 실결제·실데이터를 사용하지 않는다.
