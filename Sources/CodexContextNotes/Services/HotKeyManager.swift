import AppKit
import Carbon.HIToolbox
import Foundation

struct AppShortcut: Codable, Equatable {
    var keyCode: UInt32
    var modifierFlagsRawValue: UInt

    static let `default` = AppShortcut(
        keyCode: UInt32(kVK_ANSI_N),
        modifierFlagsRawValue: NSEvent.ModifierFlags([.control, .option]).rawValue
    )

    var modifierFlags: NSEvent.ModifierFlags {
        NSEvent.ModifierFlags(rawValue: modifierFlagsRawValue)
            .intersection([.command, .control, .option, .shift])
    }

    var carbonModifiers: UInt32 {
        var value: UInt32 = 0
        if modifierFlags.contains(.command) {
            value |= UInt32(cmdKey)
        }
        if modifierFlags.contains(.control) {
            value |= UInt32(controlKey)
        }
        if modifierFlags.contains(.option) {
            value |= UInt32(optionKey)
        }
        if modifierFlags.contains(.shift) {
            value |= UInt32(shiftKey)
        }
        return value
    }

    var displayName: String {
        let modifierText = [
            modifierFlags.contains(.control) ? "Control" : nil,
            modifierFlags.contains(.option) ? "Option" : nil,
            modifierFlags.contains(.shift) ? "Shift" : nil,
            modifierFlags.contains(.command) ? "Command" : nil
        ]
        .compactMap { $0 }

        return (modifierText + [Self.keyName(for: keyCode)]).joined(separator: "-")
    }

    func matches(_ event: NSEvent) -> Bool {
        UInt32(event.keyCode) == keyCode &&
            event.modifierFlags.intersection([.command, .control, .option, .shift]) == modifierFlags
    }

    static func from(event: NSEvent) -> AppShortcut? {
        let flags = event.modifierFlags.intersection([.command, .control, .option, .shift])
        let activationModifiers = flags.intersection([.command, .control, .option])
        guard !activationModifiers.isEmpty, !modifierOnlyKeyCodes.contains(UInt32(event.keyCode)) else {
            return nil
        }

        return AppShortcut(keyCode: UInt32(event.keyCode), modifierFlagsRawValue: flags.rawValue)
    }

    static func keyName(for keyCode: UInt32) -> String {
        keyNames[keyCode] ?? "Key \(keyCode)"
    }

    private static let modifierOnlyKeyCodes: Set<UInt32> = [
        UInt32(kVK_Command),
        UInt32(kVK_RightCommand),
        UInt32(kVK_Shift),
        UInt32(kVK_RightShift),
        UInt32(kVK_Option),
        UInt32(kVK_RightOption),
        UInt32(kVK_Control),
        UInt32(kVK_RightControl),
        UInt32(kVK_Function)
    ]

    private static let keyNames: [UInt32: String] = [
        UInt32(kVK_ANSI_A): "A",
        UInt32(kVK_ANSI_B): "B",
        UInt32(kVK_ANSI_C): "C",
        UInt32(kVK_ANSI_D): "D",
        UInt32(kVK_ANSI_E): "E",
        UInt32(kVK_ANSI_F): "F",
        UInt32(kVK_ANSI_G): "G",
        UInt32(kVK_ANSI_H): "H",
        UInt32(kVK_ANSI_I): "I",
        UInt32(kVK_ANSI_J): "J",
        UInt32(kVK_ANSI_K): "K",
        UInt32(kVK_ANSI_L): "L",
        UInt32(kVK_ANSI_M): "M",
        UInt32(kVK_ANSI_N): "N",
        UInt32(kVK_ANSI_O): "O",
        UInt32(kVK_ANSI_P): "P",
        UInt32(kVK_ANSI_Q): "Q",
        UInt32(kVK_ANSI_R): "R",
        UInt32(kVK_ANSI_S): "S",
        UInt32(kVK_ANSI_T): "T",
        UInt32(kVK_ANSI_U): "U",
        UInt32(kVK_ANSI_V): "V",
        UInt32(kVK_ANSI_W): "W",
        UInt32(kVK_ANSI_X): "X",
        UInt32(kVK_ANSI_Y): "Y",
        UInt32(kVK_ANSI_Z): "Z",
        UInt32(kVK_ANSI_0): "0",
        UInt32(kVK_ANSI_1): "1",
        UInt32(kVK_ANSI_2): "2",
        UInt32(kVK_ANSI_3): "3",
        UInt32(kVK_ANSI_4): "4",
        UInt32(kVK_ANSI_5): "5",
        UInt32(kVK_ANSI_6): "6",
        UInt32(kVK_ANSI_7): "7",
        UInt32(kVK_ANSI_8): "8",
        UInt32(kVK_ANSI_9): "9",
        UInt32(kVK_Space): "Space",
        UInt32(kVK_Return): "Return",
        UInt32(kVK_Escape): "Escape",
        UInt32(kVK_Tab): "Tab",
        UInt32(kVK_Delete): "Delete",
        UInt32(kVK_ForwardDelete): "Forward Delete",
        UInt32(kVK_LeftArrow): "Left Arrow",
        UInt32(kVK_RightArrow): "Right Arrow",
        UInt32(kVK_UpArrow): "Up Arrow",
        UInt32(kVK_DownArrow): "Down Arrow",
        UInt32(kVK_F1): "F1",
        UInt32(kVK_F2): "F2",
        UInt32(kVK_F3): "F3",
        UInt32(kVK_F4): "F4",
        UInt32(kVK_F5): "F5",
        UInt32(kVK_F6): "F6",
        UInt32(kVK_F7): "F7",
        UInt32(kVK_F8): "F8",
        UInt32(kVK_F9): "F9",
        UInt32(kVK_F10): "F10",
        UInt32(kVK_F11): "F11",
        UInt32(kVK_F12): "F12"
    ]
}

enum ShortcutPreferences {
    static let storageKey = "openPanelShortcut"

    static func load() -> AppShortcut {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let shortcut = try? JSONDecoder().decode(AppShortcut.self, from: data) else {
            return .default
        }
        return shortcut
    }

    static func save(_ shortcut: AppShortcut) {
        if let data = try? JSONEncoder().encode(shortcut) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}

final class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var globalMonitor: Any?
    private var localMonitor: Any?

    func register() {
        unregister()

        let shortcut = ShortcutPreferences.load()
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

        var registeredRef: EventHotKeyRef?
        let hotKeyID = EventHotKeyID(signature: fourCharCode("CCNT"), id: 1)
        let registerStatus = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &registeredRef
        )
        hotKeyRef = registeredRef
        UserDefaults.standard.set(Int(registerStatus), forKey: "hotKeyRegisterStatus")
        UserDefaults.standard.set(shortcut.displayName, forKey: "hotKeyDisplayName")
        AppLogger.write("RegisterEventHotKey \(shortcut.displayName) status \(registerStatus)")

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            if shortcut.matches(event) {
                AppLogger.write("global monitor shortcut received")
                NotificationCenter.default.post(name: .codexContextNotesHotKeyPressed, object: nil)
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if shortcut.matches(event) {
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

    func unregister() {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let eventHandler {
            RemoveEventHandler(eventHandler)
            self.eventHandler = nil
        }
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
            self.globalMonitor = nil
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
            self.localMonitor = nil
        }
    }

    deinit {
        unregister()
    }
}

private func fourCharCode(_ string: String) -> OSType {
    string.utf8.reduce(0) { ($0 << 8) + OSType($1) }
}

extension Notification.Name {
    static let codexContextNotesHotKeyPressed = Notification.Name("codexContextNotesHotKeyPressed")
    static let codexContextNotesShortcutSelfTestRequested = Notification.Name("codexContextNotesShortcutSelfTestRequested")
    static let codexContextNotesHotKeyChanged = Notification.Name("codexContextNotesHotKeyChanged")
}
