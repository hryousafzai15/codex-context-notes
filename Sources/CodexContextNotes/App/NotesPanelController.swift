import AppKit
import SwiftUI

@MainActor
final class NotesPanelController: NSObject, NSWindowDelegate {
    private static let defaultSize = NSSize(width: 470, height: 530)

    private let model: NotesPanelModel
    private lazy var panel: NSPanel = makePanel()

    var isVisible: Bool {
        panel.isVisible
    }

    init(model: NotesPanelModel) {
        self.model = model
        super.init()
    }

    func show(context: CodexContext) {
        model.load(context: context)

        present()
    }

    func present() {
        restoreFrameOrCenter()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        AppLogger.write("panel visible \(panel.isVisible)")
    }

    func beginContextRefresh() {
        model.beginContextRefresh()
    }

    func showSettings() {
        restoreFrameOrCenter()
        model.showSettings()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        AppLogger.write("panel settings visible \(panel.isVisible)")
    }

    func close() {
        panel.orderOut(nil)
    }

    private func makePanel() -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: Self.defaultSize),
            styleMask: [.titled, .closable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.title = "Codex Context Notes"
        panel.appearance = NSAppearance(named: .vibrantDark)
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false
        panel.hidesOnDeactivate = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        panel.minSize = Self.defaultSize
        panel.collectionBehavior = [.fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: NotesPanelView(model: model))
        panel.delegate = self
        return panel
    }

    private func restoreFrameOrCenter() {
        if let savedFrame = UserDefaults.standard.string(forKey: "panelFrame") {
            let frame = NSRectFromString(savedFrame)
            if isUsableSavedFrame(frame) {
                panel.setFrame(frame, display: true)
                return
            }
        }
        panel.setFrame(NSRect(origin: .zero, size: Self.defaultSize), display: false)
        panel.center()
    }

    private func isUsableSavedFrame(_ frame: NSRect) -> Bool {
        guard frame.width >= Self.defaultSize.width, frame.height >= Self.defaultSize.height else {
            return false
        }

        return NSScreen.screens.contains { screen in
            screen.visibleFrame.intersects(frame)
        }
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        sender.orderOut(nil)
        return false
    }

    func windowDidMove(_ notification: Notification) {
        UserDefaults.standard.set(NSStringFromRect(panel.frame), forKey: "panelFrame")
    }

    func windowDidResize(_ notification: Notification) {
        UserDefaults.standard.set(NSStringFromRect(panel.frame), forKey: "panelFrame")
    }
}
