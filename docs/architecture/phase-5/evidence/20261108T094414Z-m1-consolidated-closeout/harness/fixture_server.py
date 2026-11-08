#!/usr/bin/env python3
"""Validation-only synthetic loopback fixture. No personal data or external requests."""
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/sw.js':
            payload=b"self.addEventListener('install',e=>self.skipWaiting());self.addEventListener('activate',e=>e.waitUntil(clients.claim()));"
            kind='application/javascript'
        else:
            payload=b'<!doctype html><meta charset="utf-8"><title>VX M1 synthetic fixture</title><p>Disposable local storage fixture.</p>'
            kind='text/html'
        self.send_response(200);self.send_header('Content-Type',kind);self.send_header('Cache-Control','no-store');self.send_header('Content-Length',str(len(payload)));self.end_headers();self.wfile.write(payload)
    def log_message(self,*args): pass

