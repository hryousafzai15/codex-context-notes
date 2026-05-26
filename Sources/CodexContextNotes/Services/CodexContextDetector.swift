import AppKit
import CoreGraphics
import Foundation

final class CodexContextDetector {
    private let sessionIndexReader: CodexSessionIndexReader
    private let accessibilityReader: CodexAccessibilityContextReader

    init(
        sessionIndexReader: CodexSessionIndexReader = CodexSessionIndexReader(),
        accessibilityReader: CodexAccessibilityContextReader = CodexAccessibilityContextReader()
    ) {
        self.sessionIndexReader = sessionIndexReader
        self.accessibilityReader = accessibilityReader
    }

    func prewarm() {
        sessionIndexReader.prewarm()
    }

    func detect() -> CodexContext {
        let codexApp = NSWorkspace.shared.runningApplications.first { app in
            app.bundleIdentifier == "com.openai.codex" || app.localizedName == "Codex"
        }

        if let codexApp,
           let hints = accessibilityReader.activeWindowHints(for: codexApp.processIdentifier) {
            let session = sessionIndexReader.userSession(matchingThreadName: hints.chatTitle)
            let projectName = session == nil ? accessibilityReader.projectName(containing: hints.chatTitle, for: codexApp.processIdentifier) : nil
            return Self.context(
                fromActiveChatTitle: hints.chatTitle,
                projectName: projectName,
                appName: codexApp.localizedName ?? "Codex",
                session: session
            )
        }

        if let codexApp, let window = Self.bestWindow(for: codexApp.processIdentifier) {
            return Self.context(from: window, appName: codexApp.localizedName ?? "Codex", session: sessionIndexReader.latestUserSession(includeRecentFile: false))
        }

        if codexApp != nil, let session = sessionIndexReader.latestUserSession(includeRecentFile: false) {
            return CodexContext(
                projectName: session.cwd.map { URL(fileURLWithPath: $0).lastPathComponent } ?? "Current Codex project",
                projectPath: session.cwd,
                chatTitle: session.threadName,
                chatId: session.id,
                filePath: session.recentFilePath,
                sourceAppName: "Codex",
                sourceWindowTitle: nil,
                detectionSummary: session.recentFilePath == nil ? "Latest Codex session" : "Latest Codex file reference",
                detectedAt: Date()
            )
        }

        if let frontmost = NSWorkspace.shared.frontmostApplication,
           let window = Self.bestWindow(for: frontmost.processIdentifier) {
            return Self.context(from: window, appName: frontmost.localizedName ?? "Current app", session: nil)
        }

        return .fallback()
    }

    static func context(from window: DetectedWindow, appName: String, session: CodexSessionSnapshot?, now: Date = Date()) -> CodexContext {
        let title = window.title?.trimmingCharacters(in: .whitespacesAndNewlines)
        let project = session?.cwd.map { URL(fileURLWithPath: $0).lastPathComponent } ?? inferProjectName(from: title, appName: appName)
        let filePath = inferFilePath(from: title) ?? session?.recentFilePath
        let chatTitle = inferChatTitle(from: title, projectName: project, filePath: filePath) ?? session?.threadName

        return CodexContext(
            projectName: project,
            projectPath: session?.cwd,
            chatTitle: chatTitle,
            chatId: session?.id,
            filePath: filePath,
            sourceAppName: appName,
            sourceWindowTitle: title,
            detectionSummary: session?.recentFilePath != nil && filePath == session?.recentFilePath ? "Latest Codex file reference" : (title == nil ? "Latest app window" : "Window title"),
            detectedAt: now
        )
    }

    static func context(
        fromActiveChatTitle chatTitle: String,
        projectName hintedProjectName: String?,
        appName: String,
        session: CodexSessionSnapshot?,
        now: Date = Date()
    ) -> CodexContext {
        let projectName = session?.cwd.map { URL(fileURLWithPath: $0).lastPathComponent } ??
            hintedProjectName ??
            "Current Codex project"

        return CodexContext(
            projectName: projectName,
            projectPath: session?.cwd,
            chatTitle: chatTitle,
            chatId: session?.id,
            filePath: nil,
            sourceAppName: appName,
            sourceWindowTitle: chatTitle,
            detectionSummary: session?.id == nil ? "Active Codex window" : "Active Codex chat",
            detectedAt: now
        )
    }

    static func inferProjectName(from title: String?, appName: String) -> String {
        guard let title, !title.isEmpty else {
            return appName == "Codex" ? "Current Codex project" : appName
        }

        let separators = [" — ", " - ", " | "]
        for separator in separators where title.contains(separator) {
            let parts = title.components(separatedBy: separator).filter { !$0.isEmpty }
            if let first = parts.first {
                return first
            }
        }

        return title.count > 48 ? String(title.prefix(48)) : title
    }

    static func inferChatTitle(from title: String?, projectName: String, filePath: String?) -> String? {
        guard let title, !title.isEmpty else {
            return nil
        }

        var cleaned = title
        cleaned = cleaned.replacingOccurrences(of: projectName, with: "")
        if let filePath {
            cleaned = cleaned.replacingOccurrences(of: filePath, with: "")
            cleaned = cleaned.replacingOccurrences(of: URL(fileURLWithPath: filePath).lastPathComponent, with: "")
        }
        cleaned = cleaned.replacingOccurrences(of: "Codex", with: "")
        cleaned = cleaned.replacingOccurrences(of: #"[\-|—|/|\\]+"#, with: " ", options: .regularExpression)
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleaned.isEmpty ? nil : cleaned
    }

    static func inferFilePath(from title: String?) -> String? {
        guard let title else {
            return nil
        }

        let pattern = #"([A-Za-z0-9_./~\-]+?\.(swift|tsx|ts|jsx|js|css|html|md|json|py|rb|go|rs|java|kt|c|cc|cpp|h|hpp))"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return nil
        }

        let range = NSRange(title.startIndex..<title.endIndex, in: title)
        guard let match = regex.firstMatch(in: title, range: range),
              let matchRange = Range(match.range(at: 1), in: title) else {
            return nil
        }

        return String(title[matchRange])
    }

    private static func bestWindow(for pid: pid_t) -> DetectedWindow? {
        guard let rawWindows = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        return rawWindows.compactMap { info -> DetectedWindow? in
            guard let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t,
                  ownerPID == pid else {
                return nil
            }

            let title = info[kCGWindowName as String] as? String
            let boundsDictionary = info[kCGWindowBounds as String] as? NSDictionary
            let bounds = boundsDictionary.flatMap { CGRect(dictionaryRepresentation: $0) } ?? .zero
            guard bounds.width > 120, bounds.height > 80 else {
                return nil
            }

            return DetectedWindow(title: title, bounds: bounds)
        }
        .sorted { $0.bounds.width * $0.bounds.height > $1.bounds.width * $1.bounds.height }
        .first
    }
}

struct DetectedWindow: Equatable {
    var title: String?
    var bounds: CGRect
}
