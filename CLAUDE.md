# COTP

macOS menu bar app that auto-copies OTP codes from notifications to clipboard.

## Build

```
./build.sh
```

Builds release binary via SPM, assembles .app bundle with icons, codesigns, installs to /Applications, and launches.

## Architecture

- `Sources/main.swift` — entry point, NSApplication setup
- `Sources/AppDelegate.swift` — menu bar, accessibility permission flow, clipboard
- `Sources/NotificationWatcher.swift` — AXObserver on com.apple.notificationcenterui, text extraction
- `Sources/OTPParser.swift` — keyword-gated regex detection for digit/alpha OTP patterns
- `Sources/ToastWindow.swift` — HUD-style floating panel for visual feedback

## Key details

- Watches NotificationCenter process via AXObserver (kAXWindowCreatedNotification, kAXValueChangedNotification, kAXFocusedUIElementChangedNotification)
- Loop prevention: skips text containing "COTP", 3s temporal suppression, 30s dedup set
- OTP detection requires keyword match before pattern scan
- Toast is a borderless NSPanel (not a system notification), so it never triggers the AX observer
