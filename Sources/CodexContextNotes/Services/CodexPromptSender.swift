import AppKit
import ApplicationServices
import Carbon.HIToolbox
import Foundation

enum PromptSendResult: Equatable {
    case pasteRequested
    case copiedNeedsAccessibility
    case copiedNoCodex
}

final class CodexPromptSender {
    func insertIntoCodex(_ text: String) -> PromptSendResult {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return .copiedNoCodex
        }

        let previousClipboard = NSPasteboard.general.string(forType: .string)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(trimmed, forType: .string)

        guard let codex = NSWorkspace.shared.runningApplications.first(where: { app in
            app.bundleIdentifier == "com.openai.codex" || app.localizedName == "Codex"
        }) else {
            return .copiedNoCodex
        }

        codex.activate(options: [.activateAllWindows])

        guard AXIsProcessTrusted() else {
            return .copiedNeedsAccessibility
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            Self.sendPasteKeystroke()
        }
        if let previousClipboard {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(previousClipboard, forType: .string)
            }
        }
        return .pasteRequested
    }

    func requestAccessibilityPermission() {
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    private static func sendPasteKeystroke() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: CGKeyCode(kVK_ANSI_V), keyDown: false)
        keyDown?.flags = CGEventFlags.maskCommand
        keyUp?.flags = CGEventFlags.maskCommand
        keyDown?.post(tap: CGEventTapLocation.cghidEventTap)
        keyUp?.post(tap: CGEventTapLocation.cghidEventTap)
    }
}
