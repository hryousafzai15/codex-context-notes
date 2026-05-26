import AppKit
import ApplicationServices
import SwiftUI

struct PanelSettingsView: View {
    var onDone: () -> Void

    @AppStorage("hotKeyRegisterStatus") private var hotKeyRegisterStatus = 0
    @AppStorage("hotKeyDisplayName") private var hotKeyDisplayName = AppShortcut.default.displayName
    @AppStorage("lastShortcutSelfTestAt") private var lastShortcutSelfTestAt: Double = 0
    @State private var accessibilityTrusted = AXIsProcessTrusted()
    @State private var shortcut = ShortcutPreferences.load()

    var body: some View {
        VStack(spacing: 0) {
            settingsHeader

            ScrollView {
                VStack(spacing: 10) {
                    shortcutSection
                    contextSection
                    privacySection
                    appSection
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 14)
            }
            .scrollIndicators(.hidden)
        }
        .onAppear {
            accessibilityTrusted = AXIsProcessTrusted()
            shortcut = ShortcutPreferences.load()
        }
        .onChange(of: shortcut) { _, newValue in
            saveShortcut(newValue)
        }
    }

    private var settingsHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: onDone) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .bold))
                    .frame(width: 30, height: 30)
                    .background(Color.white.opacity(0.08), in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(.white.opacity(0.12), lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .help("Back to notes")

            NotoMascotView(size: 42)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 7, height: 7)

                    Text("Noto settings")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.56))
                }

                Text("Settings")
                    .font(.system(size: 23, weight: .semibold))

                Text("Shortcut, tracking, and private local notes")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
                    .lineLimit(1)
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 36)
        .padding(.bottom, 10)
    }

    private var shortcutSection: some View {
        SettingsCard(systemImage: "keyboard", title: "Shortcut", detail: shortcutStatusText, detailColor: shortcutStatusColor) {
            ViewThatFits(in: .horizontal) {
                shortcutHorizontalLayout
                shortcutStackedLayout
            }

            shortcutFooter
        }
    }

    private var shortcutHorizontalLayout: some View {
        HStack(alignment: .top, spacing: 12) {
            shortcutDescription
                .frame(minWidth: 160, alignment: .leading)

            Spacer(minLength: 8)

            ShortcutRecorderButton(shortcut: $shortcut)
        }
    }

    private var shortcutStackedLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            shortcutDescription
                .frame(maxWidth: .infinity, alignment: .leading)

            ShortcutRecorderButton(shortcut: $shortcut, fillsWidth: true)
        }
    }

    private var shortcutDescription: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Open notes panel")
                .font(.callout.weight(.semibold))

            Text("Choose the key combination that opens and closes Noto.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.52))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var shortcutFooter: some View {
        HStack(spacing: 8) {
            Button {
                saveShortcut(.default)
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
                    .font(.caption.weight(.semibold))
                    .frame(height: 28)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 10)
            .background(Color.white.opacity(0.07), in: Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(.white.opacity(0.10), lineWidth: 1)
            }

            Spacer()

            if lastShortcutSelfTestAt > 0 {
                Text("Tested \(Date(timeIntervalSince1970: lastShortcutSelfTestAt).formatted(date: .omitted, time: .shortened))")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.42))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
        }
    }

    private var contextSection: some View {
        SettingsCard(
            systemImage: accessibilityTrusted ? "checkmark.shield" : "exclamationmark.triangle",
            title: "Context tracking",
            detail: accessibilityTrusted ? "Enabled" : "Permission needed",
            detailColor: accessibilityTrusted ? .green : .orange
        ) {
            Text(accessibilityTrusted ? "Noto can read the active Codex window to attach notes to the right context." : "Enable Accessibility so Noto can detect the currently selected Codex chat and project.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.58))
                .fixedSize(horizontal: false, vertical: true)

            Button {
                let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
                AXIsProcessTrustedWithOptions(options)
                accessibilityTrusted = AXIsProcessTrusted()
            } label: {
                Label("Request permission", systemImage: "lock.open")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 32)
            }
            .buttonStyle(.plain)
            .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(.white.opacity(0.11), lineWidth: 1)
            }
        }
    }

    private var privacySection: some View {
        SettingsCard(systemImage: "lock", title: "Privacy", detail: "Local only", detailColor: .blue) {
            Text("Noto stores notes in Application Support. They are not sent to Codex until you press Insert into Codex.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.58))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var appSection: some View {
        SettingsCard(systemImage: "app", title: "App", detail: "Version \(appVersion)", detailColor: .white.opacity(0.52)) {
            VStack(alignment: .leading, spacing: 5) {
                Text("Build \(appBuild)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))

                Text("The bundle id and signing identity stay stable so Accessibility trust can survive rebuilds.")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.46))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var shortcutStatusText: String {
        if hotKeyRegisterStatus == 0 {
            return hotKeyDisplayName
        }
        return "Failed \(hotKeyRegisterStatus)"
    }

    private var shortcutStatusColor: Color {
        hotKeyRegisterStatus == 0 ? .blue : .red
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

private struct SettingsCard<Content: View>: View {
    var systemImage: String
    var title: String
    var detail: String
    var detailColor: Color
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 9) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.82))
                    .frame(width: 15)

                Text(title)
                    .font(.callout.weight(.semibold))

                Spacer()

                Text(detail)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(detailColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }

            content
        }
        .padding(12)
        .settingsSurface(cornerRadius: 12)
    }
}

private struct ShortcutRecorderButton: View {
    @Binding var shortcut: AppShortcut
    var fillsWidth = false
    @State private var isRecording = false
    @State private var warningText: String?
    @State private var monitor: Any?

    var body: some View {
        VStack(alignment: fillsWidth ? .leading : .trailing, spacing: 6) {
            Button {
                isRecording ? stopRecording() : startRecording()
            } label: {
                HStack(spacing: 7) {
                    Image(systemName: isRecording ? "keyboard.badge.ellipsis" : "keyboard")
                        .font(.system(size: 12, weight: .semibold))

                    Text(isRecording ? "Press shortcut" : shortcut.displayName)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .frame(width: fillsWidth ? nil : 142, height: 32)
                .frame(maxWidth: fillsWidth ? .infinity : nil)
                .background(isRecording ? Color.blue.opacity(0.24) : Color.white.opacity(0.08), in: Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(isRecording ? Color.blue.opacity(0.55) : Color.white.opacity(0.11), lineWidth: 1)
                }
            }
            .buttonStyle(.plain)

            if let warningText {
                Text(warningText)
                    .font(.caption2)
                    .foregroundStyle(.orange)
                    .multilineTextAlignment(fillsWidth ? .leading : .trailing)
                    .frame(width: fillsWidth ? nil : 154, alignment: fillsWidth ? .leading : .trailing)
                    .frame(maxWidth: fillsWidth ? .infinity : nil, alignment: .leading)
            } else if isRecording {
                Text("Control, Option, or Command plus a key.")
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.48))
                    .multilineTextAlignment(fillsWidth ? .leading : .trailing)
                    .frame(width: fillsWidth ? nil : 154, alignment: fillsWidth ? .leading : .trailing)
                    .frame(maxWidth: fillsWidth ? .infinity : nil, alignment: .leading)
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
                warningText = "Use a normal key with a modifier."
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

private extension View {
    func settingsSurface(cornerRadius: CGFloat) -> some View {
        self
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(Color.white.opacity(0.035))
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.13), lineWidth: 1)
            }
    }
}
