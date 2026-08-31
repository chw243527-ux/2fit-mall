# NICE 계약 전 요구사항 조사 메모

공식 KISA 본인확인 지원포털의 2024년 3월 자료는 본인확인서비스 이용기관 취약점 자체점검 체크리스트 및 보안가이드를 게시하고 있다.

공식 FAQ에 따르면 이 체크리스트는 웹사이트에 본인확인서비스를 도입한 경우에 적용되며, 앱에만 적용한 경우에는 해당 없음으로 회신할 수 있다. 또한 법적 의무사항은 아니지만 미제출 시 본인확인서비스 계약 및 제공이 어려울 수 있다고 안내한다.

공식 자료 링크:
- 체크리스트 및 보안가이드: https://identity.kisa.or.kr/web/main/bbs/guide/44?cp=1&sortOrder=BA_REGDATE&sortDirection=DESC&bcId=guide&baNotice=false&baCommSelec=false&baOpenDay=false&baUse=true
- 공식 FAQ: https://identity.kisa.or.kr/web/main/bbs/guide/75?cp=1&sortOrder=BA_REGDATE&sortDirection=DESC&bcId=guide&baNotice=false&baCommSelec=false&baOpenDay=false&baUse=true
- 체크리스트 PDF 다운로드: https://identity.kisa.or.kr/web/main/file/download/uu/4b09e2c3f5f544f9a37ba401ec8153c5

구현 방향:
1. NICE 연동 전에도 서버 측 파라미터 검증, 중요 페이지 접근 제어, 데이터 재사용 방지, TLS 및 헤더를 먼저 강화한다.
2. NICE 계약 후 발급되는 사이트 식별값·암호화 키·콜백/리턴 URL을 서버 전용 환경변수로 연결한다. 현재 저장소에는 NICE 연동 코드나 CI/DI 처리 코드가 확인되지 않는다.
3. CI/DI 원문을 프런트엔드나 URL·로그에 노출하지 않고, 필요한 경우 서버에서 최소한으로 암호화 또는 일방향 식별값으로 처리한다.
4. KISA 문서의 최신 항목 수와 기관별 제출 양식은 계약하는 본인확인기관 또는 대행사가 제공하는 최종 양식과 대조한다. 첨부사진은 7개 항목으로 보이나 공식 FAQ에는 개정에 따라 8개 항목으로 변경되었다는 안내가 있으므로, 계약 상대방의 최신 양식을 최종 기준으로 사용해야 한다.
