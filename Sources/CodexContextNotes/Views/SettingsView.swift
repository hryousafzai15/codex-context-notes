import ApplicationServices
import SwiftUI

struct SettingsView: View {
    @AppStorage("hotKeyRegisterStatus") private var hotKeyRegisterStatus = 0
    @AppStorage("legacyHotKeyRegisterStatus") private var legacyHotKeyRegisterStatus = 0
    @AppStorage("lastShortcutSelfTestAt") private var lastShortcutSelfTestAt: Double = 0
    @State private var accessibilityTrusted = AXIsProcessTrusted()

    var body: some View {
        Form {
            Section("Shortcut") {
                Text("Open current Codex notes with Control-Option-N.")
                Text("The app detects the current Codex window when the shortcut fires.")
                    .foregroundStyle(.secondary)
                Text(hotKeyRegisterStatus == 0 ? "Shortcut is registered." : "Shortcut registration failed with status \(hotKeyRegisterStatus). Use the menu bar Open Current Context command.")
                    .foregroundStyle(hotKeyRegisterStatus == 0 ? Color.secondary : Color.red)
                Text(legacyHotKeyRegisterStatus == 0 ? "Old shortcut Control-Option-Command-N also works for now." : "Old shortcut fallback is unavailable.")
                    .foregroundStyle(.secondary)
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
                Text("Bundle identity stays signed as com.hussainrehman.CodexContextNotes so Accessibility trust can survive rebuilds.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 420)
        .onAppear {
            accessibilityTrusted = AXIsProcessTrusted()
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }

    private var appBuild: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "local"
    }
}
