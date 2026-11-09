# Architecture review

The window controller owns a private storage composition. The native adapter owns WebKit objects and tracks weak disposal references. Core authorizes view construction and retirement. The main workspace and each Mini use separate compositions. The host presents views and owns tab and split metadata. See the baseline recovery report for the traced paths.
