self.addEventListener('install', event => event.waitUntil(self.skipWaiting()));
self.addEventListener('activate', event => event.waitUntil(self.clients.claim()));
self.addEventListener('fetch', event => {
  if (new URL(event.request.url).pathname === '/sw-probe') {
    event.respondWith(caches.open('wsf1').then(cache => cache.match('/marker')).then(response => response || new Response('')));
  }
});
