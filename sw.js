/**
 * ResQ Offline Service Worker
 * Ensures 100% offline execution even in Airplane mode without any internet access.
 */

const CACHE_NAME = 'resq-offline-v6';
const ASSETS_TO_CACHE = [
  './',
  './index.html',
  './style.css',
  './app.js',
  './manifest.json',
  './icon-192.png',
  './icon-512.png',
  './icon.svg'
];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      console.log('[ResQ SW] Caching offline shell assets');
      return cache.addAll(ASSETS_TO_CACHE);
    }).then(() => self.skipWaiting())
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.map((key) => {
          if (key !== CACHE_NAME) {
            console.log('[ResQ SW] Removing old cache', key);
            return caches.delete(key);
          }
        })
      );
    }).then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // Let API calls go to network, or fail naturally so app.js offline engine handles them
  if (url.pathname.startsWith('/api/')) {
    return;
  }

  // Cache-first strategy for static assets (HTML, CSS, JS, icons) with ignoreSearch so query strings match
  event.respondWith(
    caches.match(event.request, { ignoreSearch: true }).then((cachedResponse) => {
      if (cachedResponse) {
        return cachedResponse;
      }
      return fetch(event.request).then((networkResponse) => {
        if (networkResponse && networkResponse.status === 200) {
          const responseToCache = networkResponse.clone();
          caches.open(CACHE_NAME).then((cache) => cache.put(event.request, responseToCache));
        }
        return networkResponse;
      });
    }).catch(() => {
      // Offline fallback: serve index.html for page navigation
      if (event.request.mode === 'navigate') {
        return caches.match('./index.html');
      }
      return caches.match(event.request, { ignoreSearch: true });
    })
  );
});
