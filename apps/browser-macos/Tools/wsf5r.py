#!/usr/bin/env python3
"""Owned loopback fixture and callback-injection runner for WS-F5R."""
from http.cookies import CookieError, SimpleCookie
import secrets
import signal
import sys
import threading
from urllib.parse import parse_qs

sys.dont_write_bytecode = True
import wsf5

LOGIN = b"""<title>Fixture sign in</title><form method="post" action="/fixture-login">
<label>Account <input name="account"></label>
<label>Password <input name="password" type="password"></label>
<button type="submit">Sign in</button></form>"""
SIGNED_IN = b"""<title>Fixture signed in</title><p id="account">Owned synthetic account</p>
<form method="post" action="/fixture-logout"><button type="submit">Sign out</button></form>"""
SIGNED_OUT = b"""<title>Fixture signed out</title><a href="/fixture-signin">Sign in</a>"""
COOKIE_NAME = "wsf5r_fixture"
SYNTHETIC_ACCOUNT = {"account": ["fixture"], "password": ["disposable"]}


class RecoveryFixture(wsf5.Fixture):
    def respond(self, status, body=b"", *, location=None, cookie=None):
        self.send_response(status)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.send_header("Connection", "close")
        if location:
            self.send_header("Location", location)
        if cookie:
            self.send_header("Set-Cookie", cookie)
        self.end_headers()
        self.close_connection = True
        try:
            self.wfile.write(body)
        except (BrokenPipeError, ConnectionResetError):
            pass

    def token(self):
        try:
            cookies = SimpleCookie(self.headers.get("Cookie", ""))
            return cookies[COOKIE_NAME].value if COOKIE_NAME in cookies else None
        except CookieError:
            return None

    def do_GET(self):
        if self.path == "/fixture-signin":
            return self.respond(200, LOGIN)
        if self.path.partition("?")[0] == "/fixture-account":
            with self.server.session_lock:
                signed_in = self.token() in self.server.sessions
            return self.respond(200 if signed_in else 401, SIGNED_IN if signed_in else SIGNED_OUT)
        return super().do_GET()

    def do_POST(self):
        if self.path not in ("/fixture-login", "/fixture-logout"):
            return self.respond(404)
        origin = f"http://127.0.0.1:{self.server.server_port}"
        if self.headers.get("Origin") != origin or self.headers.get("Host") != origin.removeprefix("http://"):
            return self.respond(403)
        try:
            size = int(self.headers.get("Content-Length", "0"))
            if not 0 <= size <= 256:
                return self.respond(400)
            values = parse_qs(self.rfile.read(size).decode("ascii"), max_num_fields=2)
        except (ValueError, UnicodeError, OSError):
            return self.respond(400)
        if self.path == "/fixture-logout":
            with self.server.session_lock:
                self.server.sessions.discard(self.token())
            return self.respond(303, location="/fixture-account",
                                cookie=f"{COOKIE_NAME}=; Max-Age=0; Path=/; HttpOnly; SameSite=Strict")
        if values != SYNTHETIC_ACCOUNT:
            return self.respond(403)
        with self.server.session_lock:
            if len(self.server.sessions) >= 16:
                return self.respond(503)
            self.server.sessions.discard(self.token())
            token = secrets.token_urlsafe(24)
            self.server.sessions.add(token)
        return self.respond(303, location="/fixture-account",
                            cookie=f"{COOKIE_NAME}={token}; Path=/; HttpOnly; SameSite=Strict")


class RecoveryFixtureServer(wsf5.FixtureServer):
    def __init__(self):
        self.sessions = set()
        self.session_lock = threading.Lock()
        super().__init__(RecoveryFixture)


def interrupt(_signum, _frame):
    raise KeyboardInterrupt


if __name__ == "__main__":
    signal.signal(signal.SIGTERM, interrupt)
    root = wsf5.REPO / "docs/architecture/phase-5/reports/WS-F5R/evidence/execution-01"
    sys.exit(wsf5.main(evidence_root=root, flag="--wsf5r-qualification", server_factory=RecoveryFixtureServer))
