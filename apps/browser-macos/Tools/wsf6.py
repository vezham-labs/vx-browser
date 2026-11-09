#!/usr/bin/env python3
"""Run the isolated workspace or private-recovery regression on an owned loopback origin."""
import argparse
import signal
import socket
import sys
import threading

sys.dont_write_bytecode = True

import wsf5
from wsf5r import RecoveryFixture, RecoveryFixtureServer, interrupt


class WorkspaceFixture(RecoveryFixture):
    def do_GET(self):
        route = self.path.partition("?")[0]
        behavior = route.split("/")[1]
        if behavior not in {"f6-delay", "f6-redirect", "f6-failure", "f6-http-error"}:
            return super().do_GET()
        with self.server.lock:
            second = route in self.server.seen
            self.server.seen.add(route)
        if second:
            if behavior == "f6-redirect":
                return self.respond(302, b"", location="/beta")
            if behavior == "f6-http-error":
                return self.respond(404, b"<title>Missing</title>")
            if behavior == "f6-failure":
                self.close_connection = True
                try:
                    self.connection.shutdown(socket.SHUT_RDWR)
                except OSError:
                    pass
                return
            if self.server.stopping.wait(1):
                return
        return self.respond(200, b"<title>Workspace fixture</title>")


class WorkspaceFixtureServer(RecoveryFixtureServer):
    def __init__(self):
        self.lock = threading.Lock()
        self.seen = set()
        super().__init__()
        self.RequestHandlerClass = WorkspaceFixture


if __name__ == "__main__":
    selection = argparse.ArgumentParser(add_help=False)
    selection.add_argument("--suite", choices=("workspace", "recovery"), default="workspace")
    suite, args = selection.parse_known_args()
    sys.argv[1:] = args
    signal.signal(signal.SIGTERM, interrupt)
    wsf5.BUNDLE_ID = "internal.vezham.browser.wsf6.qualification"
    evidence = wsf5.APP_ROOT / "build/wsf6-evidence"
    evidence.mkdir(parents=True, exist_ok=True)
    flag = "--wsf6-qualification" if suite.suite == "workspace" else "--wsf5r-qualification"
    sys.exit(wsf5.main(evidence_root=evidence, flag=flag, server_factory=WorkspaceFixtureServer))
