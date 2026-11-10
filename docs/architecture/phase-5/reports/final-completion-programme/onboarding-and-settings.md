# Onboarding, menus and settings

The first launch presents a native welcome sheet explaining Spaces, sidebar organization, private browsing, the command bar and DuckDuckGo. It offers System, Light and Dark appearance using the existing allowlisted appearance setting. Done and Skip both persist a single completion boolean in the app preferences. No browsing record, credential or workspace layout is stored there. Help and Settings can reopen welcome. The separate Debug qualification bundle isolates preferences used by this run.

| Area | Current behavior |
| --- | --- |
| Application | Settings and Quit |
| File | Command bar for new destinations, blank tab, current page in Mini |
| Edit | Cut, copy, paste, select all through the responder chain |
| View | Sidebar toggle, focus address, command bar |
| Navigation | Back, forward, reload, stop, copy address |
| Bookmarks | Manage temporary bookmarks within the active private session |
| Window | Minimize and close |
| Help | Reopen welcome |
| Settings | Appearance, search provider disclosure, privacy/availability explanation and welcome link |

Menu commands validate against the active window and navigation state. Mini keeps its own private scope and address field. The welcome does not ask users to import browsing data, configure a profile or change OS permissions. Search provider selection, profile management, secure import/export, downloads, persistent browser settings and default-handler management remain outside the implemented onboarding slice.
