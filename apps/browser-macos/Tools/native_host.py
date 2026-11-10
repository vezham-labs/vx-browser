#!/usr/bin/env python3
"""Native host build/bundle audit/launch. WS-F1 adds an explicitly assigned engine adapter."""
import argparse
import hashlib
import json
import os
import pathlib
import platform
import plistlib
import re
import shutil
import subprocess

APP_ROOT = pathlib.Path(__file__).resolve().parents[1]
DERIVED_DATA = pathlib.Path(os.environ.get("VEZHAM_DERIVED_DATA", APP_ROOT / "build/DerivedData")).resolve()
CHROME = APP_ROOT / "Chrome"
CHROME_OUTPUT = APP_ROOT / "build/chrome"
APP = DERIVED_DATA / "Build/Products/Debug/VezhamBrowser.app"


def run(command):
    subprocess.run(command, cwd=APP_ROOT, check=True)


def capture(command):
    return subprocess.run(command, cwd=APP_ROOT, capture_output=True, text=True, check=True)


def build_chrome():
    subprocess.run([
        str(APP_ROOT.parents[1] / "node_modules/.bin/vite"),
        "build", "--outDir", str(CHROME_OUTPUT), "--emptyOutDir",
    ], cwd=CHROME, check=True)
    shutil.copyfile(CHROME / "index.html", CHROME_OUTPUT / "index.html")


def build(qualification=False, reliability=False, workspace=False, unsigned=False):
    settings = ["PRODUCT_BUNDLE_IDENTIFIER=internal.vezham.browser.wsf4.qualification"] if qualification else []
    if reliability:
        settings = ["PRODUCT_BUNDLE_IDENTIFIER=internal.vezham.browser.wsf5.qualification"]
    if workspace:
        settings = ["PRODUCT_BUNDLE_IDENTIFIER=internal.vezham.browser.wsf6.qualification"]
    if unsigned:
        settings = ["CODE_SIGNING_ALLOWED=NO"]
    run([
        "xcodebuild", "-project", str(APP_ROOT / "VezhamBrowser.xcodeproj"),
        "-scheme", "VezhamBrowser", "-configuration", "Release" if unsigned else "Debug", "-destination",
        "platform=macOS,arch=" + platform.machine(), "-derivedDataPath", str(DERIVED_DATA), "build",
        "ARCHS=" + platform.machine(), "ONLY_ACTIVE_ARCH=YES", "MACOSX_DEPLOYMENT_TARGET=26.0", *settings
    ])


def audit():
    executable = APP / "Contents/MacOS/VezhamBrowser"
    if not executable.is_file():
        raise SystemExit("Build the browser before auditing or launching it.")
    run(["codesign", "--verify", "--strict", "--verbose=2", str(APP)])
    signature = capture(["codesign", "-d", "--verbose=4", str(APP)]).stderr
    entitlement_output = capture(["codesign", "-d", "--entitlements", ":-", str(APP)]).stdout
    entitlements = plistlib.loads(entitlement_output.encode())
    info = plistlib.loads((APP / "Contents/Info.plist").read_bytes())
    load_commands = capture(["otool", "-l", str(executable)]).stdout
    minimums = re.findall(r"\bminos\s+(\S+)", load_commands)
    minimum = minimums[0] if minimums else None
    linked_libraries = capture(["otool", "-L", str(executable)]).stdout
    checks = {
        "binaryMinimumOS26": bool(minimums) and all(value == "26.0" for value in minimums),
        "bundleMinimumOS26": info.get("LSMinimumSystemVersion") == "26.0",
        "hardenedRuntimeEnabled": "runtime" in signature,
        "adHocDevelopmentSignature": "Signature=adhoc" in signature,
        "boundedSandboxEntitlements": entitlements == {"com.apple.security.app-sandbox": True, "com.apple.security.network.client": True},
        "nativeWebKitLinked": "WebKit.framework" in linked_libraries,
        "nativeSwiftUILinked": "SwiftUI.framework" in linked_libraries,
        "noWebChromeResources": not any(
            p.suffix in {".js", ".css", ".html"} or p.name == "chrome"
            for p in (APP / "Contents/Resources").rglob("*")
        ),
        "noWebsiteMessageHandlerRegistration": "addScriptMessageHandler" not in
            (APP_ROOT / "StorageRuntime/Sources/BrowserNativeStorage/NativeWebKitStorage.swift").read_text(),
        "engineIndependentCore": all("import WebKit" not in p.read_text() and "import AppKit" not in p.read_text()
            for target in ["BrowserDomain", "BrowserPorts", "BrowserCore"]
            for p in (APP_ROOT.parents[1] / "qualification/webkit-storage-f0/Sources" / target).glob("*.swift")),
        "noMediaPurposeStrings": not any(key in info for key in ["NSCameraUsageDescription", "NSMicrophoneUsageDescription"])
    }
    result = {
        "status": "passed" if all(checks.values()) else "failed", "checks": checks,
        "executableSHA256": hashlib.sha256(executable.read_bytes()).hexdigest(),
        "entitlements": entitlements, "minimumOS": minimum, "minimumOSValuesAcrossArchitectures": minimums, "linkedLibraries": linked_libraries,
        "method": "WS-F4 development bundle/static boundary audit, not runtime/release security qualification. No macOS26 runtime or Developer ID/notarization claim."
    }
    output = APP_ROOT / "build/wsf1-bundle-audit.json"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(json.dumps(result, indent=2, sort_keys=True))
    if not all(checks.values()):
        raise SystemExit(1)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["build", "chrome", "audit", "launch"])
    parser.add_argument("--qualification", action="store_true")
    parser.add_argument("--wsf5-qualification", action="store_true")
    parser.add_argument("--wsf6-qualification", action="store_true")
    parser.add_argument("--unsigned-release", action="store_true")
    args = parser.parse_args()
    action = args.action
    if action == "build":
        build(args.qualification, args.wsf5_qualification, args.wsf6_qualification, args.unsigned_release)
    elif action == "chrome":
        build_chrome()
    elif action == "audit":
        audit()
    else:
        if not APP.is_dir():
            raise SystemExit("Build the browser first.")
        run(["open", "-n", "-W", "-a", str(APP)])


if __name__ == "__main__":
    main()
