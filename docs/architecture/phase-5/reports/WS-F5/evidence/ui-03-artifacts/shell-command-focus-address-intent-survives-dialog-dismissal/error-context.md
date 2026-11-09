# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: shell.spec.ts >> command focus-address intent survives dialog dismissal
- Location: tests/shell.spec.ts:216:5

# Error details

```
Test timeout of 15000ms exceeded.
```

# Page snapshot

```yaml
- generic [ref=e3]:
  - banner [ref=e4]:
    - generic [ref=e5]:
      - button "Hide sidebar" [ref=e6] [cursor=pointer]
      - button "Go back" [disabled]
      - button "Go forward" [disabled]
      - button "Reload" [disabled]
      - generic [ref=e9]:
        - generic "Connection information unavailable" [ref=e10]
        - textbox "Address and search" [disabled]:
          - /placeholder: Start a private session to browse
        - generic [ref=e14]: ⌘L
      - button "Add split" [disabled]
      - button "Open command palette" [ref=e15] [cursor=pointer]
      - button "Navigation actions" [ref=e17] [cursor=pointer]
      - generic [ref=e18]: Workspace
  - generic [ref=e20]:
    - complementary "Workspace sidebar" [ref=e21]:
      - generic [ref=e22]:
        - strong [ref=e26]: Vezham
        - button "Workspace actions" [ref=e27] [cursor=pointer]
      - generic "Spaces" [ref=e28]:
        - button "Switch to Personal" [pressed] [ref=e29] [cursor=pointer]:
          - generic [ref=e30]: "1"
          - text: Personal
        - button "Create Space" [disabled]
      - generic [ref=e31]:
        - strong [ref=e32]: Personal
        - button "Space actions" [disabled]
      - button "Start private session ⌘T" [ref=e33] [cursor=pointer]:
        - text: Start private session
        - generic [ref=e34]: ⌘T
      - tablist "Browser tabs" [ref=e35]:
        - generic [ref=e36]: Today
      - generic [ref=e37]:
        - button "Bookmarks" [ref=e38] [cursor=pointer]
        - button "History" [ref=e39] [cursor=pointer]
        - button "Downloads" [ref=e40] [cursor=pointer]
        - button "Profiles" [ref=e41] [cursor=pointer]
        - button "Settings" [ref=e42] [cursor=pointer]
      - generic [ref=e43]: No active profile
      - separator "Resize sidebar" [ref=e48]
    - main "Browser workspace" [ref=e50]:
      - generic [ref=e52]:
        - generic [ref=e53]: Vezham browser
        - heading "Your next idea." [level=1] [ref=e56]
        - paragraph [ref=e57]: Open a private session to explore the web. Your tabs and website data are discarded when the session ends.
        - button "Start private session" [ref=e58] [cursor=pointer]
        - generic [ref=e59]: Protected profiles are currently unavailable.
  - contentinfo [ref=e63]:
    - generic [ref=e64]: Ready for a private session
    - button "Commands ⌘K" [ref=e65] [cursor=pointer]:
      - text: Commands
      - generic [ref=e66]: ⌘K
  - dialog "Browser commands" [ref=e68]:
    - generic [ref=e69]:
      - textbox "Find a command" [active] [ref=e73]:
        - /placeholder: Find a command…
        - text: Focus address
      - button "Close commands" [ref=e74] [cursor=pointer]
    - generic [ref=e75]:
      - button "Focus address ⌘L" [disabled]:
        - text: Focus address
        - generic: ⌘L
```