import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var statusMenuItem: NSMenuItem!
    private var watcher: NotificationWatcher?
    private var permissionTimer: Timer?
    private let toast = ToastWindow()

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
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
        NSWorkspace.shared.open(URL(string: "https://cotp.vlad.studio")!)
    }

    @objc private func openAccessibility() {
        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility")!)
    }

    private func onOTPDetected(_ otp: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(otp, forType: .string)
        toast.show(code: otp)
    }
}
