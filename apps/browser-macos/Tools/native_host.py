#!/usr/bin/env python3
"""Native host build/bundle audit/launch. WS-F1 adds an explicitly assigned engine adapter."""
import argparse
import hashlib
import json
import pathlib
import platform
import plistlib
import re
import subprocess

APP_ROOT = pathlib.Path(__file__).resolve().parents[1]
DERIVED_DATA = APP_ROOT / "build/DerivedData"
APP = DERIVED_DATA / "Build/Products/Debug/VezhamBrowser.app"


def run(command):
    subprocess.run(command, cwd=APP_ROOT, check=True)


def capture(command):
    return subprocess.run(command, cwd=APP_ROOT, capture_output=True, text=True, check=True)


def build():
    run([
        "xcodebuild", "-project", str(APP_ROOT / "VezhamBrowser.xcodeproj"),
        "-scheme", "VezhamBrowser", "-configuration", "Debug", "-destination",
        "platform=macOS,arch=" + platform.machine(), "-derivedDataPath", str(DERIVED_DATA), "build",
        "ARCHS=" + platform.machine(), "ONLY_ACTIVE_ARCH=YES", "MACOSX_DEPLOYMENT_TARGET=26.0"
    ])


def audit():
    executable = APP / "Contents/MacOS/VezhamBrowser"
    if not executable.is_file():
        raise SystemExit("Build the M0 host before auditing or launching it.")
    run(["codesign", "--verify", "--strict", "--verbose=2", str(APP)])
    signature = capture(["codesign", "-d", "--verbose=4", str(APP)]).stderr
    entitlement_output = capture(["codesign", "-d", "--entitlements", ":-", str(APP)]).stdout
    entitlements = plistlib.loads(entitlement_output.encode())
    info = plistlib.loads((APP / "Contents/Info.plist").read_bytes())
    load_commands = capture(["otool", "-l", str(executable)]).stdout
    section = re.search(r"cmd LC_BUILD_VERSION(?P<values>.*?)(?=Load command|$)", load_commands, re.S)
    minimums = re.findall(r"\bminos\s+(\S+)", load_commands)
    minimum = minimums[0] if minimums else None
    linked_libraries = capture(["otool", "-L", str(executable)]).stdout
    source = "\n".join(p.read_text() for p in (APP_ROOT / "Sources").rglob("*.swift"))
    checks = {
        "binaryMinimumOS26": bool(minimums) and all(value == "26.0" for value in minimums),
        "bundleMinimumOS26": info.get("LSMinimumSystemVersion") == "26.0",
        "hardenedRuntimeEnabled": "runtime" in signature,
        "adHocDevelopmentSignature": "Signature=adhoc" in signature,
        "boundedSandboxEntitlements": entitlements == {"com.apple.security.app-sandbox": True, "com.apple.security.network.client": True},
        "nativeWebKitLinked": "WebKit.framework" in linked_libraries,
        "noPrivilegedWebsiteMessageBridge": "WKScriptMessageHandler" not in source,
        "engineIndependentCore": all("import WebKit" not in p.read_text() and "import AppKit" not in p.read_text()
            for target in ["BrowserDomain", "BrowserPorts", "BrowserCore"]
            for p in (APP_ROOT.parents[1] / "qualification/webkit-storage-f0/Sources" / target).glob("*.swift")),
        "noMediaPurposeStrings": not any(key in info for key in ["NSCameraUsageDescription", "NSMicrophoneUsageDescription"])
    }
    result = {
        "status": "passed" if all(checks.values()) else "failed", "checks": checks,
        "executableSHA256": hashlib.sha256(executable.read_bytes()).hexdigest(),
        "entitlements": entitlements, "minimumOS": minimum, "minimumOSValuesAcrossArchitectures": minimums, "linkedLibraries": linked_libraries,
        "method": "WS-F1 development bundle/static boundary audit, not runtime/release security qualification. No macOS26 runtime or Developer ID/notarization claim."
    }
    output = APP_ROOT / "build/wsf1-bundle-audit.json"
    output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(json.dumps(result, indent=2, sort_keys=True))
    if not all(checks.values()):
        raise SystemExit(1)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["build", "audit", "launch"])
    action = parser.parse_args().action
    if action == "build":
        build()
    elif action == "audit":
        audit()
    else:
        if not APP.is_dir():
            raise SystemExit("Build the M0 host first.")
        run(["open", "-n", "-W", "-a", str(APP)])


if __name__ == "__main__":
    main()
