import Foundation

struct ContextNote: Codable, Equatable, Identifiable {
    var id: String { context.storageKey }
    var context: CodexContext
    var body: String
    var todos: [NoteTodo]
    var reminders: [NoteReminder]
    var createdAt: Date
    var updatedAt: Date

    static func empty(context: CodexContext, now: Date = Date()) -> ContextNote {
        ContextNote(
            context: context,
            body: "",
            todos: [],
            reminders: [],
            createdAt: now,
            updatedAt: now
        )
    }
}

struct NoteTodo: Codable, Equatable, Identifiable {
    var id: UUID
    var text: String
    var isDone: Bool
    var createdAt: Date

    init(id: UUID = UUID(), text: String, isDone: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.isDone = isDone
        self.createdAt = createdAt
    }
}

struct NoteReminder: Codable, Equatable, Identifiable {
    var id: UUID
    var text: String
    var dueText: String
    var createdAt: Date

    init(id: UUID = UUID(), text: String, dueText: String, createdAt: Date = Date()) {
        self.id = id
        self.text = text
        self.dueText = dueText
        self.createdAt = createdAt
    }
}
