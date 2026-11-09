# Permissions

App-level mediation keeps the existing Ask policy for supported authorized capabilities. It denies missing purpose strings, unsupported kinds and mismatched scope/main-frame origin. Combined camera/microphone requires both purpose strings. Allowed main-frame navigations change a view's permission token, so old async replies cannot authorize the newer document. A callback also rechecks the view, generation, scope fence and current URL. Stale or unpresentable pending tickets are cancelled. Diagnostics record entry and decision category only.

WS-F2's media script error and geolocation timeout remain historical evidence. The new fixture explicitly checks availability and secure context before requesting media. It independently records OS microphone status, configured purpose text, delegate entry and terminal result. Geolocation distinguishes deny from native or script timeout. A native denial now requires the corresponding delegate terminal event and page-level denial. An unavailable API or absent delegate is inconclusive. Positive Ask/Allow, OS-device integration, native permission persistence, revocation and cross-profile/restart behavior remain unqualified.

[Latest observations and limits](qualification-matrix.md) · [Earlier failure analysis](../WS-F2R-owner-handoff/native-failure-analysis.md)
