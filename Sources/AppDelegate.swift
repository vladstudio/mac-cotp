import AppKit
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var statusMenuItem: NSMenuItem!
    private var watcher: NotificationWatcher?
    private var permissionTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        checkAccessibilityAndStart()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if let img = NSImage(systemSymbolName: "doc.on.doc", accessibilityDescription: "COTP") {
                img.isTemplate = true
                button.image = img
            } else {
                button.title = "OTP"
            }
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "COTP", action: nil, keyEquivalent: "")
        statusMenuItem = NSMenuItem(title: "Status: starting…", action: nil, keyEquivalent: "")
        statusMenuItem.isEnabled = false
        menu.addItem(statusMenuItem)
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = menu
    }

    private func checkAccessibilityAndStart() {
        if AXIsProcessTrusted() {
            startWatcher()
            return
        }

        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let opts = [key: true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
        statusMenuItem.title = "Status: waiting for permission…"

        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] timer in
            if AXIsProcessTrusted() {
                timer.invalidate()
                self?.startWatcher()
            }
        }
    }

    private func startWatcher() {
        statusMenuItem.title = "Status: watching"
        watcher = NotificationWatcher { [weak self] otp in
            self?.onOTPDetected(otp)
        }
        watcher?.start()
    }

    private func onOTPDetected(_ otp: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(otp, forType: .string)

        let content = UNMutableNotificationContent()
        content.title = "COTP"
        content.body = "Copied to clipboard: \(otp)"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
