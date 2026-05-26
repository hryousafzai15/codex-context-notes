import Foundation

struct CodexContext: Codable, Equatable {
    var projectName: String
    var projectPath: String?
    var chatTitle: String?
    var chatId: String?
    var filePath: String?
    var sourceAppName: String
    var sourceWindowTitle: String?
    var detectionSummary: String
    var detectedAt: Date

    var displayTitle: String {
        if let filePath, !filePath.isEmpty {
            return URL(fileURLWithPath: filePath).lastPathComponent
        }
        if let chatTitle, !chatTitle.isEmpty {
            return chatTitle
        }
        return projectName
    }

    var displaySubtitle: String {
        var parts = [projectName]
        if let chatTitle, !chatTitle.isEmpty {
            parts.append(chatTitle)
        }
        if let filePath, !filePath.isEmpty {
            parts.append(filePath)
        }
        return parts.joined(separator: " / ")
    }

    var noteKindLabel: String {
        if filePath != nil {
            return "File note"
        }
        if chatTitle != nil || chatId != nil {
            return "Chat note"
        }
        return "Project note"
    }

    var storageKey: String {
        let projectIdentity = projectPath ?? projectName
        let scope = filePath ?? chatId ?? chatTitle ?? "project"
        return CodexContext.normalizedKey([projectIdentity, scope].joined(separator: "|"))
    }

    static func fallback(now: Date = Date()) -> CodexContext {
        CodexContext(
            projectName: "Current Codex context",
            projectPath: nil,
            chatTitle: nil,
            chatId: nil,
            filePath: nil,
            sourceAppName: "Codex",
            sourceWindowTitle: nil,
            detectionSummary: "Fallback context",
            detectedAt: now
        )
    }

    static func normalizedKey(_ raw: String) -> String {
        raw
            .lowercased()
            .replacingOccurrences(of: #"[^a-z0-9._/-]+"#, with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    }
}
