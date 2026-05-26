import AppKit
import Carbon.HIToolbox
import Foundation

final class HotKeyManager {
    private struct ShortcutRegistration {
        let id: UInt32
        let keyCode: UInt32
        let modifiers: UInt32
        let statusKey: String
        let logName: String
    }

    private static let registrations = [
        ShortcutRegistration(
            id: 1,
            keyCode: UInt32(kVK_ANSI_N),
            modifiers: UInt32(optionKey | controlKey),
            statusKey: "hotKeyRegisterStatus",
            logName: "primary"
        ),
        ShortcutRegistration(
            id: 2,
            keyCode: UInt32(kVK_ANSI_N),
            modifiers: UInt32(cmdKey | optionKey | controlKey),
            statusKey: "legacyHotKeyRegisterStatus",
            logName: "legacy"
        )
    ]

    private var hotKeyRefs: [EventHotKeyRef] = []
    private var eventHandler: EventHandlerRef?
    private var globalMonitor: Any?
    private var localMonitor: Any?

    func register() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))

        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            { _, event, _ in
                var hotKeyID = EventHotKeyID()
                if let event {
                    GetEventParameter(
                        event,
                        EventParamName(kEventParamDirectObject),
                        EventParamType(typeEventHotKeyID),
                        nil,
                        MemoryLayout<EventHotKeyID>.size,
                        nil,
                        &hotKeyID
                    )
                }
                AppLogger.write("hotkey callback received id \(hotKeyID.id)")
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .codexContextNotesHotKeyPressed, object: nil)
                }
                return noErr
            },
            1,
            &eventType,
            nil,
            &eventHandler
        )
        AppLogger.write("InstallEventHandler status \(handlerStatus)")

        for registration in Self.registrations {
            var hotKeyRef: EventHotKeyRef?
            let hotKeyID = EventHotKeyID(signature: fourCharCode("CCNT"), id: registration.id)
            let registerStatus = RegisterEventHotKey(
                registration.keyCode,
                registration.modifiers,
                hotKeyID,
                GetApplicationEventTarget(),
                0,
                &hotKeyRef
            )
            if let hotKeyRef {
                hotKeyRefs.append(hotKeyRef)
            }
            UserDefaults.standard.set(Int(registerStatus), forKey: registration.statusKey)
            AppLogger.write("RegisterEventHotKey \(registration.logName) status \(registerStatus)")
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if Self.matchesShortcut(event) {
                AppLogger.write("global monitor shortcut received")
                NotificationCenter.default.post(name: .codexContextNotesHotKeyPressed, object: nil)
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if Self.matchesShortcut(event) {
                AppLogger.write("local monitor shortcut received")
                NotificationCenter.default.post(name: .codexContextNotesHotKeyPressed, object: nil)
                return nil
            }
            return event
        }
    }

    func runSelfTest() {
        AppLogger.write("shortcut self-test requested")
        NotificationCenter.default.post(name: .codexContextNotesShortcutSelfTestRequested, object: nil)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "lastShortcutSelfTestAt")
    }

    deinit {
        for hotKeyRef in hotKeyRefs {
            UnregisterEventHotKey(hotKeyRef)
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
        }
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
    }

    private static func matchesShortcut(_ event: NSEvent) -> Bool {
        event.keyCode == UInt16(kVK_ANSI_N) &&
            event.modifierFlags.contains(.option) &&
            event.modifierFlags.contains(.control)
    }
}

private func fourCharCode(_ string: String) -> OSType {
    string.utf8.reduce(0) { ($0 << 8) + OSType($1) }
}

extension Notification.Name {
    static let codexContextNotesHotKeyPressed = Notification.Name("codexContextNotesHotKeyPressed")
    static let codexContextNotesShortcutSelfTestRequested = Notification.Name("codexContextNotesShortcutSelfTestRequested")
}
