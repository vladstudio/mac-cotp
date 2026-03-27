import AppKit
import ServiceManagement
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var statusMenuItem: NSMenuItem!
    private var loginItem: NSMenuItem!
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
            if let img = Bundle.main.image(forResource: "cotp-18x2") {
                img.size = NSSize(width: 18, height: 18)
                img.isTemplate = true
                button.image = img
            } else {
                button.title = "OTP"
            }
        }

        let menu = NSMenu()
        menu.addItem(withTitle: "COTP", action: nil, keyEquivalent: "")
        statusMenuItem = NSMenuItem(title: "Status: starting…", action: #selector(openAccessibility), keyEquivalent: "")
        statusMenuItem.target = self
        menu.addItem(statusMenuItem)
        let aboutItem = NSMenuItem(title: "About COTP", action: #selector(openAbout), keyEquivalent: "")
        aboutItem.target = self
        menu.addItem(aboutItem)
        menu.addItem(.separator())
        loginItem = NSMenuItem(title: "Start on Login", action: #selector(toggleLoginItem), keyEquivalent: "")
        loginItem.target = self
        menu.addItem(loginItem)
        setupLoginItem()
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
        statusMenuItem.title = "Waiting for permission…"

        permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] timer in
            if AXIsProcessTrusted() {
                timer.invalidate()
                self?.startWatcher()
            }
        }
    }

    private func startWatcher() {
        statusMenuItem.title = "Watching"
        watcher = NotificationWatcher { [weak self] otp in
            self?.onOTPDetected(otp)
        }
        watcher?.start()
    }

    @objc private func openAbout() {
        if let url = URL(string: "https://cotp.vlad.studio") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func openAccessibility() {
        let urlString = "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }

    @objc private func toggleLoginItem() {
        let service = SMAppService.mainApp
        do {
            if service.status == .enabled {
                try service.unregister()
            } else {
                try service.register()
            }
        } catch {
            NSLog("[COTP] Failed to toggle login item: \(error)")
            let alert = NSAlert()
            alert.messageText = "Failed to change login item settings"
            alert.informativeText = error.localizedDescription
            alert.alertStyle = .warning
            alert.runModal()
        }
        loginItem.state = service.status == .enabled ? .on : .off
    }

    private func setupLoginItem() {
        let service = SMAppService.mainApp
        if !UserDefaults.standard.bool(forKey: "loginItemConfigured") {
            UserDefaults.standard.set(true, forKey: "loginItemConfigured")
            try? service.register()
        }
        loginItem.state = service.status == .enabled ? .on : .off
    }

    private func onOTPDetected(_ otp: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(otp, forType: .string)
        let content = UNMutableNotificationContent()
        content.title = "COTP"
        content.body = "Copied: \(otp)"
        UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
    }
}
