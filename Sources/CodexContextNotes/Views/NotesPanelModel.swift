import Foundation
import SwiftUI

@MainActor
final class NotesPanelModel: ObservableObject {
    @Published var note: ContextNote
    @Published var includeNote = true
    @Published var includeTodos = true
    @Published var includeReminders = false
    @Published var selectedTodoIDs: Set<UUID> = []
    @Published var selectedReminderIDs: Set<UUID> = []
    @Published var newTodoText = ""
    @Published var newReminderText = ""
    @Published var newReminderDueText = ""
    @Published var statusText = "Private until you insert it."
    @Published var isLoadingContext = true

    private let repository: NotesRepository
    private let promptSender: CodexPromptSender

    init(repository: NotesRepository, promptSender: CodexPromptSender) {
        self.repository = repository
        self.promptSender = promptSender
        self.note = repository.note(for: .fallback())
    }

    var promptPreview: String {
        PromptFormatter.format(
            note: note,
            includeBody: includeNote,
            includeTodos: includeTodos,
            includeReminders: includeReminders,
            selectedTodoIDs: selectedTodoIDs,
            selectedReminderIDs: selectedReminderIDs
        )
    }

    var openTodoCount: Int {
        note.todos.filter { !$0.isDone }.count
    }

    var hasExistingContent: Bool {
        !note.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
            !note.todos.isEmpty ||
            !note.reminders.isEmpty
    }

    var selectedOpenTodoCount: Int {
        note.todos.filter { !$0.isDone && selectedTodoIDs.contains($0.id) }.count
    }

    var selectedReminderCount: Int {
        note.reminders.filter { selectedReminderIDs.contains($0.id) }.count
    }

    func load(context: CodexContext) {
        note = repository.note(for: context)
        selectedTodoIDs = Set(note.todos.filter { !$0.isDone }.map(\.id))
        selectedReminderIDs = Set(note.reminders.map(\.id))
        isLoadingContext = false
        statusText = hasExistingContent ? "Loaded saved notes for this context." : "No saved notes yet. Add the first one."
    }

    func beginContextRefresh() {
        isLoadingContext = true
        statusText = "Detecting current Codex context..."
    }

    func save() {
        repository.save(note)
    }

    func addTodo() {
        let trimmed = newTodoText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return
        }
        let todo = NoteTodo(text: trimmed)
        note.todos.insert(todo, at: 0)
        selectedTodoIDs.insert(todo.id)
        newTodoText = ""
        save()
    }

    func toggleTodo(_ todo: NoteTodo) {
        guard let index = note.todos.firstIndex(where: { $0.id == todo.id }) else {
            return
        }
        note.todos[index].isDone.toggle()
        if note.todos[index].isDone {
            selectedTodoIDs.remove(todo.id)
        } else {
            selectedTodoIDs.insert(todo.id)
        }
        save()
    }

    func toggleTodoSelection(_ todo: NoteTodo) {
        if selectedTodoIDs.contains(todo.id) {
            selectedTodoIDs.remove(todo.id)
        } else {
            selectedTodoIDs.insert(todo.id)
        }
    }

    func deleteTodo(_ todo: NoteTodo) {
        note.todos.removeAll { $0.id == todo.id }
        selectedTodoIDs.remove(todo.id)
        save()
    }

    func addReminder() {
        let text = newReminderText.trimmingCharacters(in: .whitespacesAndNewlines)
        let due = newReminderDueText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return
        }
        let reminder = NoteReminder(text: text, dueText: due.isEmpty ? "Later" : due)
        note.reminders.insert(reminder, at: 0)
        selectedReminderIDs.insert(reminder.id)
        newReminderText = ""
        newReminderDueText = ""
        save()
    }

    func toggleReminderSelection(_ reminder: NoteReminder) {
        if selectedReminderIDs.contains(reminder.id) {
            selectedReminderIDs.remove(reminder.id)
        } else {
            selectedReminderIDs.insert(reminder.id)
        }
    }

    func deleteReminder(_ reminder: NoteReminder) {
        note.reminders.removeAll { $0.id == reminder.id }
        selectedReminderIDs.remove(reminder.id)
        save()
    }

    func insertIntoCodex() {
        let prompt = promptPreview
        guard !prompt.isEmpty else {
            statusText = "Choose at least one non-empty block first."
            return
        }

        switch promptSender.insertIntoCodex(prompt) {
        case .pasteRequested:
            statusText = "Sent to Codex composer. Review before sending."
        case .copiedNeedsAccessibility:
            statusText = "Copied. Enable Accessibility permission to auto-paste."
            promptSender.requestAccessibilityPermission()
        case .copiedNoCodex:
            statusText = "Copied. Open Codex to paste it into the composer."
        }
    }
}
