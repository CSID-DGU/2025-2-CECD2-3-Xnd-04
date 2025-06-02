importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.0.0/firebase-messaging-compat.js');

const firebaseConfig = {
    apiKey: "AIzaSyDBJ70D3x5xmmA_doiKsQMD0mkj2C3OUeE",
    authDomain: "food-notification-af4dd.firebaseapp.com",
    projectId: "food-notification-af4dd",
    storageBucket: "food-notification-af4dd.firebasestorage.app",
    messagingSenderId: "260905646650",
    appId: "1:260905646650:web:ac1c902f9659fa8a8d5303",
    measurementId: "G-N9KV1KLT9S"
};

firebase.initializeApp(firebaseConfig);
const messaging = firebase.messaging();

// 'install' 이벤트 추가
self.addEventListener('install', (event) => {
    console.log('Service Worker 설치됨');
    self.skipWaiting(); // 즉시 활성화
});

// 'activate' 이벤트 추가
self.addEventListener('activate', (event) => {
    console.log('Service Worker 활성화됨');
    event.waitUntil(self.clients.claim()); // 즉시 제어권 획득
});

messaging.onBackgroundMessage((payload) => {
    console.log('백그라운드 메시지 받음:', payload);

    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/static/icon.png'
    };

    self.registration.showNotification(notificationTitle, notificationOptions);
});