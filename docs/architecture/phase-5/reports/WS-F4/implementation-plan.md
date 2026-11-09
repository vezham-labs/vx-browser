# Implementation and build

Starting HEAD `6386944c14b58930ad2a47fa225d0facd373ecc4` matched the brief. The checkout was clean on `timeline`. The milestone reused the existing Xcode application, BrowserCore and BrowserNativeStorage packages, root React/HeroUI v3 dependencies and local tooling. No dependency or lockfile changes.

1. Build the React browser chrome with Vite and Tailwind. Xcode copies the generated local HTML, script and CSS into the signed app.
2. Compose the AppKit window and independent chrome/content surfaces. Route chrome commands through validated input, a native state snapshot and explicit failures.
3. Reuse the existing Core and WebKit adapter for explicit private scopes. Add interactive navigation commands to the private adapter path and keep named-store qualification policy separate.
4. Implement toolbar, tab actions, sidebar, new tab, command palette, provisional bookmarks and available/blocked settings.
5. Verify the compiled browser with contract, stand-in frontend and actual native fixture tests. Preserve earlier unsuccessful attempts.

From repository root, use the existing browser-macos build target or its underlying command:

```sh
python3 apps/browser-macos/Tools/native_host.py build
python3 apps/browser-macos/Tools/native_host.py audit
python3 apps/browser-macos/Tools/native_host.py launch
```

For a direct Xcode build, first run `python3 apps/browser-macos/Tools/native_host.py chrome`. For runtime evidence, build with `--qualification`, which uses an isolated bundle ID, then run `wsf4_native.py` with a new run name and the WS-F4 evidence directory. Project entitlements, OS requirements and the development signing configuration remain unchanged.

[Source and feature breakdown](feature-status.md)
