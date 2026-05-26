import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let repository = NotesRepository()
    private let detector = CodexContextDetector()
    private let promptSender = CodexPromptSender()
    private let hotKeyManager = HotKeyManager()
    private let settingsWindowController = SettingsWindowController()
    private var panelController: NotesPanelController?
    private var hotKeyObserver: NSObjectProtocol?
    private var shortcutSelfTestObserver: NSObjectProtocol?
    private var hotKeyChangeObserver: NSObjectProtocol?
    private var settingsObserver: NSObjectProtocol?
    private var lastShortcutToggleAt = Date.distantPast
    private var contextRefreshTask: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        AppLogger.write("applicationDidFinishLaunching")
        NSApp.setActivationPolicy(.accessory)

        let model = NotesPanelModel(repository: repository, promptSender: promptSender)
        panelController = NotesPanelController(model: model)

        hotKeyObserver = NotificationCenter.default.addObserver(
            forName: .codexContextNotesHotKeyPressed,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            AppLogger.write("hotkey notification observed")
            Task { @MainActor in
                self?.handleShortcutPressed()
            }
        }
        hotKeyManager.register()
        detector.prewarm()

        hotKeyChangeObserver = NotificationCenter.default.addObserver(
            forName: .codexContextNotesHotKeyChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            AppLogger.write("hotkey changed")
            Task { @MainActor in
                self?.hotKeyManager.register()
            }
        }

        settingsObserver = NotificationCenter.default.addObserver(
            forName: .codexContextNotesSettingsRequested,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            AppLogger.write("settings requested")
            Task { @MainActor in
                self?.showSettingsFromMenu()
            }
        }

        shortcutSelfTestObserver = NotificationCenter.default.addObserver(
            forName: .codexContextNotesShortcutSelfTestRequested,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            AppLogger.write("shortcut self-test notification observed")
            Task { @MainActor in
                self?.showPanel()
            }
        }

        if CommandLine.arguments.contains("--open-panel") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.showPanelFromMenu()
            }
        }

        if CommandLine.arguments.contains("--open-settings") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.showSettingsFromMenu()
            }
        }

        if CommandLine.arguments.contains("--shortcut-self-test") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                self?.runShortcutSelfTestFromMenu()
            }
        }
    }

    func showPanelFromMenu() {
        showPanel()
    }

    func runShortcutSelfTestFromMenu() {
        hotKeyManager.runSelfTest()
    }

    func showSettingsFromMenu() {
        settingsWindowController.show()
    }

    private func handleShortcutPressed() {
        let now = Date()
        guard now.timeIntervalSince(lastShortcutToggleAt) > 0.08 else {
            AppLogger.write("duplicate shortcut notification ignored")
            return
        }

        lastShortcutToggleAt = now
        openPanelFromShortcut()
    }

    private func openPanelFromShortcut() {
        if panelController?.isVisible == true {
            contextRefreshTask?.cancel()
            panelController?.close()
            return
        }

        panelController?.beginContextRefresh()
        panelController?.present()
        refreshDetectedContext()
    }

    private func showPanel() {
        panelController?.beginContextRefresh()
        panelController?.present()
        refreshDetectedContext()
    }

    private func refreshDetectedContext() {
        contextRefreshTask?.cancel()
        contextRefreshTask = Task { @MainActor in
            await Task.yield()

            guard !Task.isCancelled else {
                return
            }

            let startedAt = Date()
            let context = detector.detect()
            let duration = Date().timeIntervalSince(startedAt)

            guard !Task.isCancelled else {
                return
            }

            AppLogger.write("showPanel context \(context.displaySubtitle) detection \(String(format: "%.3f", duration))s")
            panelController?.show(context: context)
        }
    }

}
