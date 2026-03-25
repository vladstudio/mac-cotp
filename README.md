# COTP

A tiny macOS menu bar app that watches your notifications for one-time passwords and copies them to your clipboard automatically.

When you receive an SMS or email with a verification code like `461995` or `FYO-IQ`, COTP grabs it instantly — no need to open the message.

## Install

```
git clone https://github.com/niceda/cotp.git
cd cotp
./build.sh
```

This builds, signs, installs to `/Applications`, and launches the app.

## How it works

COTP uses the macOS Accessibility API to watch the Notification Center process. When a notification appears, it reads the text, looks for OTP-related keywords ("code", "verification", "pin", etc.), and extracts the code using pattern matching.

Detected formats: `123456`, `123 456`, `123-456`, `12-34-56`, `FYOIQ`, `FYO-IQ`.

## Permissions

On first launch you'll be prompted to grant **Accessibility** permission:

**System Settings > Privacy & Security > Accessibility > Enable COTP**

The app polls automatically and starts working once permission is granted.

## Requirements

- macOS 13+
- Swift 5.9+
