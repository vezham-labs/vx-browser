# Concurrency and failure analysis

Serialize work on the main actor and through the existing busy gate. Termination blocks new commands synchronously, then retirement waits for the admitted host command to settle. Shutdown joins retirement. Ignore callbacks from foreign or already-fenced views. Keep reconstruction unpublished at the window level until all staged views are admitted.

The resumed review caught a teardown ownership race. Window closure can await Core with the ordinary command gate idle. A termination callback in that interval previously started a competing retirement. The controller now leaves teardown to closure once closing begins, and the adapter fence still applies. Pending retirement started before closing is joined. Late presentation commands cannot reattach content in a closing window. An injected close-boundary assertion and actual single teardown passed on the isolated app. See [case evidence](../evidence/execution-01/callback-run-01/attempt-1/result.json).
