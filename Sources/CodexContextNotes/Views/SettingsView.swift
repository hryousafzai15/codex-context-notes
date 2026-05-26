import AppKit
import ApplicationServices
import SwiftUI

struct SettingsView: View {
    @AppStorage("hotKeyRegisterStatus") private var hotKeyRegisterStatus = 0
    @AppStorage("hotKeyDisplayName") private var hotKeyDisplayName = AppShortcut.default.displayName
    @AppStorage("lastShortcutSelfTestAt") private var lastShortcutSelfTestAt: Double = 0
    @State private var accessibilityTrusted = AXIsProcessTrusted()
    @State private var shortcut = ShortcutPreferences.load()

    var body: some View {
        Form {
            Section("Shortcut") {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Open notes panel")
                            .font(.headline)
                        Text("Choose the key combination that opens Codex Context Notes.")
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    ShortcutRecorderButton(shortcut: $shortcut)
                }

                Text(hotKeyRegisterStatus == 0 ? "Shortcut is registered: \(hotKeyDisplayName)." : "Shortcut registration failed with status \(hotKeyRegisterStatus). Try a different key combination.")
                    .foregroundStyle(hotKeyRegisterStatus == 0 ? Color.secondary : Color.red)

                Button("Reset to Default") {
                    saveShortcut(.default)
                }

                if lastShortcutSelfTestAt > 0 {
                    Text("Last shortcut path self-test: \(Date(timeIntervalSince1970: lastShortcutSelfTestAt).formatted(date: .abbreviated, time: .standard))")
                        .foregroundStyle(.secondary)
                }
            }

            Section("Context Tracking") {
                Text(accessibilityTrusted ? "Active Codex chat tracking is enabled." : "Enable Accessibility so the app can read the currently selected Codex chat and project.")
                    .foregroundStyle(accessibilityTrusted ? Color.secondary : Color.orange)

                Button("Request Accessibility Permission") {
                    let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
                    AXIsProcessTrustedWithOptions(options)
                    accessibilityTrusted = AXIsProcessTrusted()
                }
            }

            Section("Privacy") {
                Text("Notes are stored locally in Application Support and are not sent to Codex unless you press Send to AI.")
                    .foregroundStyle(.secondary)
            }

            Section("App") {
                Text("Version \(appVersion) (\(appBuild))")
                    .foregroundStyle(.secondary)
                Text("Keep the bundle id and signing identity stable so Accessibility trust can survive rebuilds.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 500)
        .onAppear {
            accessibilityTrusted = AXIsProcessTrusted()
            shortcut = ShortcutPreferences.load()
        }
        .onChange(of: shortcut) { _, newValue in
            saveShortcut(newValue)
        }
    }

    private func saveShortcut(_ newValue: AppShortcut) {
        shortcut = newValue
        ShortcutPreferences.save(newValue)
        hotKeyDisplayName = newValue.displayName
        NotificationCenter.default.post(name: .codexContextNotesHotKeyChanged, object: nil)
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }

    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "local"
    }
}

private struct ShortcutRecorderButton: View {
    @Binding var shortcut: AppShortcut
    @State private var isRecording = false
    @State private var warningText: String?
    @State private var monitor: Any?

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            Button {
                isRecording ? stopRecording() : startRecording()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isRecording ? "keyboard.badge.ellipsis" : "keyboard")
                    Text(isRecording ? "Press shortcut" : shortcut.displayName)
                }
                .frame(minWidth: 160)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            if let warningText {
                Text(warningText)
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else if isRecording {
                Text("Use Control, Option, or Command with a key.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onDisappear {
            stopRecording()
        }
    }

    private func startRecording() {
        warningText = nil
        isRecording = true
        removeMonitor()

        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard isRecording else {
                return event
            }

            if event.keyCode == 53 {
                stopRecording()
                return nil
            }

            guard let captured = AppShortcut.from(event: event) else {
                warningText = "Press a normal key with Control, Option, or Command."
                return nil
            }

            shortcut = captured
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        removeMonitor()
    }

    private func removeMonitor() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
}
