import AppKit
import ApplicationServices

final class NotificationWatcher {
    private let onOTP: (String) -> Void
    private var observer: AXObserver?
    private let lock = NSLock()
    private var recentCodes: Set<String> = []
    private var suppressUntil: Date = .distantPast

    init(onOTPDetected: @escaping (String) -> Void) {
        self.onOTP = onOTPDetected
    }

    func start() {
        guard let nc = NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == "com.apple.notificationcenterui"
        }) else {
            print("[COTP] NotificationCenter process not found")
            return
        }

        let pid = nc.processIdentifier

        DispatchQueue.global(qos: .userInitiated).async { [self] in
            var obs: AXObserver?
            let refcon = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

            guard AXObserverCreate(pid, axCallback, &obs) == .success,
                  let observer = obs else {
                print("[COTP] Failed to create AXObserver")
                return
            }

            self.observer = observer
            let appElement = AXUIElementCreateApplication(pid)

            for name in [
                kAXWindowCreatedNotification,
                kAXFocusedUIElementChangedNotification,
                kAXValueChangedNotification,
            ] as [String] {
                AXObserverAddNotification(observer, appElement, name as CFString, refcon)
            }

            CFRunLoopAddSource(
                CFRunLoopGetCurrent(),
                AXObserverGetRunLoopSource(observer),
                .commonModes
            )
            print("[COTP] Watching for notifications…")
            CFRunLoopRun()
        }
    }

    fileprivate func handleAXEvent(element: AXUIElement) {
        // Check suppression window (prevents reacting to our own notification)
        lock.lock()
        let suppressed = Date() < suppressUntil
        lock.unlock()
        if suppressed { return }

        // Collect all text from the element tree
        var texts: [String] = []
        collectTexts(from: element, into: &texts, depth: 0)
        let combined = texts.joined(separator: " ")

        // Skip our own notifications
        if combined.contains("COTP") { return }

        guard let code = OTPParser.detect(in: combined) else { return }

        // Deduplicate
        lock.lock()
        let isNew = recentCodes.insert(code).inserted
        if isNew { suppressUntil = Date().addingTimeInterval(3) }
        lock.unlock()
        guard isNew else { return }

        // Expire dedup entry after 30s
        DispatchQueue.global().asyncAfter(deadline: .now() + 30) { [weak self] in
            self?.lock.lock()
            self?.recentCodes.remove(code)
            self?.lock.unlock()
        }

        DispatchQueue.main.async { [weak self] in
            self?.onOTP(code)
        }
    }

    private func collectTexts(from element: AXUIElement, into texts: inout [String], depth: Int) {
        guard depth < 10 else { return }

        var value: AnyObject?
        for attr in [kAXTitleAttribute, kAXValueAttribute, kAXDescriptionAttribute] as [String] {
            if AXUIElementCopyAttributeValue(element, attr as CFString, &value) == .success,
               let str = value as? String, !str.isEmpty {
                texts.append(str)
            }
        }

        if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &value) == .success,
           let children = value as? [AXUIElement] {
            for child in children {
                collectTexts(from: child, into: &texts, depth: depth + 1)
            }
        }
    }
}

// C-compatible callback — dispatches to the watcher instance via refcon
private func axCallback(
    _ observer: AXObserver,
    _ element: AXUIElement,
    _ notification: CFString,
    _ refcon: UnsafeMutableRawPointer?
) {
    guard let refcon = refcon else { return }
    let watcher = Unmanaged<NotificationWatcher>.fromOpaque(refcon).takeUnretainedValue()
    watcher.handleAXEvent(element: element)
}
