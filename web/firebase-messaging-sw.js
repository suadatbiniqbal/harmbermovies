importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyApubO067JYW1ih6AUii86Nu0jC6WpFcVI',
  appId: '1:227933260927:web:d0902085d37eb89738034a',
  messagingSenderId: '227933260927',
  projectId: 'harmber',
  storageBucket: 'harmber.firebasestorage.app'
});

const messaging = firebase.messaging();
