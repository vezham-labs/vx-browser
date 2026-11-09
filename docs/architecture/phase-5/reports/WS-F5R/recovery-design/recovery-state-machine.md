# Recovery state machine

Active → retiring after the adapter poisons the scope → ready after confirmed retirement → rebuilding on an explicit request → active after checked publication. Any failed retirement or rebuild leaves the window unavailable. Ready can be consumed only once.
