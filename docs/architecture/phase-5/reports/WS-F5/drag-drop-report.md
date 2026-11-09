# Native drag and drop

**BLOCKED for primary-button qualification.** Two CUA reorder attempts left the tab order unchanged. A later diagnostic run observed secondary-button mouse input, a late dragstart, and no accepted drop. Preserve the unchanged order as the observed outcome. The input was unsuitable for a primary-button pass or a conclusive product failure.

The owner approved an isolated CGEvent driver. The driver validated its target and exited 78 because the existing macOS input permission check failed. The final native state showed unchanged order and zero drag events. [Initial state](evidence/observations/drag-before.json) · [Attempt 1](evidence/observations/drag-reorder-after.json) · [Attempt 2](evidence/observations/drag-reorder-second.json) · [Diagnostic events](evidence/observations/drag-diagnostic-06.json) · [Permission result](evidence/primary-reorder-01.json) · [Final state](evidence/observations/primary-reorder-after.json)

The scoped drag changes add an explicit local payload, move drop effect, and WebKit draggable styling. Reorder remains BLOCKED. Primary-button group, Space, pin, split, cancellation and invalid drops are NOT_EXECUTED. The next qualification needs an actual primary-button gesture with a before/after native snapshot and pointer evidence. Typed organization commands and native split view creation are separate observations.
