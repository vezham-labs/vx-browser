# Session ownership

Match termination by owned view and private-session identity. Fence before notifying the host. Retain the old composition until its Core close or retire operation succeeds, its view count is zero, and its resource inventory is empty. A failed cleanup retains unavailable state.
