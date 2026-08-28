# 채팅 메시지 역할 점검

- 고객 메시지는 `chats/{roomId}/messages/{messageId}`에 `isAdmin: false`로 저장된다.
- 관리자 답변은 기존 `adminReply`가 `isAdmin: true`로 저장한다.
- 자동 안내 답변은 `systemReply`가 `isAdmin: false`, `isSystem: true`, `senderId: system`으로 저장한다.
- 고객 화면 초기화는 FirebaseAuth UID 기반 roomId를 사용한다.
- Firestore 규칙은 로그인한 본인 또는 관리자만 해당 채팅방을 읽고 생성할 수 있다.
- `ChatServiceMessage.fromMap`은 현재 `isUser: !isAdmin`으로 판정하므로 시스템 답변도 고객 메시지로 판정될 수 있다. UI에서 `isSystem`을 먼저 처리해야 한다.
- 고객 화면과 관리자 화면의 버블 표시 코드를 추가 확인해야 한다.

기록일: 2026-08-28

추가 확인:

- 고객 화면 `_buildMessageBubble`은 현재 `message.isUser`만으로 정렬·배경색·텍스트 색을 결정한다.
- `ChatServiceMessage.fromMap`에서 `isSystem: true`인 자동 답변도 `isUser: !isAdmin` 때문에 고객 메시지로 판정될 수 있다.
- 따라서 `ChatMessage`에 `isSystem`을 전달하고 버블 스타일에서 시스템 답변을 먼저 분기해야 한다.
- 자동 답변이 안 보였던 문제와 별개로, 고객 화면의 판매자/자동 안내 구분도 같은 판정 로직에서 보강해야 한다.
