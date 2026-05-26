import Foundation

enum PromptFormatter {
    static func format(
        note: ContextNote,
        includeBody: Bool,
        includeTodos: Bool,
        includeReminders: Bool,
        selectedTodoIDs: Set<UUID>? = nil,
        selectedReminderIDs: Set<UUID>? = nil
    ) -> String {
        var lines = [
            "User-selected private context for \(note.context.noteKindLabel.lowercased()) \"\(note.context.displayTitle)\":"
        ]

        if includeBody, !note.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            lines.append("")
            lines.append("Private note:")
            lines.append(note.body.trimmingCharacters(in: .whitespacesAndNewlines))
        }

        let openTodos = note.todos.filter {
            !$0.isDone &&
                !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                (selectedTodoIDs == nil || selectedTodoIDs?.contains($0.id) == true)
        }
        if includeTodos, !openTodos.isEmpty {
            lines.append("")
            lines.append("Open todos:")
            lines.append(contentsOf: openTodos.map { "- [ ] \($0.text)" })
        }

        let activeFollowUps = note.reminders.filter {
            !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                (selectedReminderIDs == nil || selectedReminderIDs?.contains($0.id) == true)
        }
        if includeReminders, !activeFollowUps.isEmpty {
            lines.append("")
            lines.append("Follow-ups:")
            lines.append(contentsOf: activeFollowUps.map { "- \($0.text) (\($0.dueText))" })
        }

        return lines.count > 1 ? lines.joined(separator: "\n") : ""
    }
}
