# Vezham Mini

Vezham Mini implements the Little Arc style quick-browser experience as a compact AppKit window with address, back/forward, reload/stop, page content, loading/failure state and Open in workspace. It has no workspace sidebar or persistent profile.

Every mini-window receives an independent nonpersistent store through NativeStorageSession. Open in workspace creates or uses an explicitly private main session, loads a new tab with the current URL, then retires and closes the mini. Transfer exports no website data.

Entry points include the tab context action, command bar, target-blank page links and the native URL delivery method. The application declares vezham://open?url= with one validated HTTPS or loopback HTTP destination. Native AppKit delivery and macOS Open delivery to the declared custom scheme were both exercised with owned loopback links. Default HTTP/HTTPS browser routing is outside this milestone.

Closing during creation schedules cleanup after construction finishes. The owner retains the controller until its view and scope retire. [Bridge](bridge-changes.md) · [Tests](test-matrix.md)
