importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyDCgy6xSme0gLoacrmcVr1XpLYI9Q_Cmww',
  authDomain: 'fayoum-queue.firebaseapp.com',
  projectId: 'fayoum-queue',
  storageBucket: 'fayoum-queue.firebasestorage.app',
  messagingSenderId: '647395303170',
  appId: '1:647395303170:web:ccfa9990b64e7c498bac1b',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notification = payload.notification || {};
  self.registration.showNotification(notification.title || 'Fayoum Students', {
    body: notification.body || 'يوجد تحديث جديد في طابور الطلاب',
    icon: '/icons/Icon-192.png',
  });
});
