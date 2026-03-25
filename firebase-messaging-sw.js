// firebase-messaging-sw.js
// FCM 웹 푸시 알림을 위한 Service Worker
// 위치: web/firebase-messaging-sw.js

importScripts('https://www.gstatic.com/firebasejs/10.13.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.0/firebase-messaging-compat.js');

// Firebase 프로젝트 설정 (fit-mall)
firebase.initializeApp({
  apiKey: 'AIzaSyCxdgTXMk08bGxrUiHpmLBqvcVsPXCm54w',
  authDomain: 'fit-mall.firebaseapp.com',
  projectId: 'fit-mall',
  storageBucket: 'fit-mall.firebasestorage.app',
  messagingSenderId: '187081765755',
  appId: '1:187081765755:web:e1d58f9cfee0aa0b5d03de',
  measurementId: 'G-JS79F5C56P',
});

const messaging = firebase.messaging();

// 백그라운드 메시지 처리
messaging.onBackgroundMessage(function(payload) {
  console.log('[SW] 백그라운드 메시지 수신:', payload);

  const notificationTitle = payload.notification?.title || '2FIT MALL';
  const notificationOptions = {
    body: payload.notification?.body || '새로운 알림이 있습니다.',
    icon: '/icons/Icon-192.png',
    badge: '/icons/Icon-192.png',
    tag: payload.data?.type || 'general',
    data: payload.data || {},
    requireInteraction: false,
    vibrate: [200, 100, 200],
    actions: [],
  };

  // 채팅 알림인 경우 즉각 반응 + 액션 추가
  if (payload.data?.type === 'chat') {
    notificationOptions.requireInteraction = true;
    notificationOptions.tag = 'chat_' + (payload.data?.roomId || 'general');
    notificationOptions.actions = [
      { action: 'view_chat', title: '채팅 확인' },
      { action: 'close', title: '닫기' },
    ];
  }

  // 주문 알림인 경우 액션 추가
  if (payload.data?.type === 'order_status') {
    notificationOptions.actions = [
      { action: 'view_order', title: '주문 확인' },
      { action: 'close', title: '닫기' },
    ];
  }

  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// 알림 클릭 처리
self.addEventListener('notificationclick', function(event) {
  event.notification.close();

  const action = event.action;
  const data = event.notification.data || {};

  let url = '/';
  if (action === 'view_chat' || data.type === 'chat') {
    url = '/#/admin?tab=chat';
  } else if (action === 'view_order' || data.type === 'order_status') {
    url = '/?tab=mypage';
  } else if (data.type === 'restock') {
    url = '/?product=' + (data.productId || '');
  } else if (data.type === 'promo') {
    url = '/?tab=home';
  }

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      // 이미 열린 탭이 있으면 포커스
      for (var client of clientList) {
        if (client.url.includes(self.location.origin) && 'focus' in client) {
          client.focus();
          client.navigate(url);
          return;
        }
      }
      // 없으면 새 창 열기
      if (clients.openWindow) {
        return clients.openWindow(url);
      }
    })
  );
});
