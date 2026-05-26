import Foundation
import Carbon.HIToolbox
import Testing
@testable import CodexContextNotes

@Test func repositoryCreatesAndPersistsContextNote() throws {
    let tempURL = FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString)
        .appendingPathComponent("notes.json")
    let repository = NotesRepository(fileURL: tempURL)
    let context = CodexContext(
        projectName: "Flightona Web",
        projectPath: nil,
        chatTitle: "Launch readiness",
        chatId: nil,
        filePath: "src/App.tsx",
        sourceAppName: "Codex",
        sourceWindowTitle: "Flightona Web - Launch readiness - src/App.tsx",
        detectionSummary: "Test",
        detectedAt: Date(timeIntervalSince1970: 0)
    )

    var note = repository.note(for: context)
    note.body = "Keep this private."
    note.todos = [NoteTodo(text: "Fix mobile nav")]
    repository.save(note)

    let reloaded = repository.note(for: context)
    #expect(reloaded.body == "Keep this private.")
    #expect(reloaded.todos.map(\.text) == ["Fix mobile nav"])
}

@Test func contextDetectorInfersFileAndChatFromWindowTitle() {
    let context = CodexContextDetector.context(
        from: DetectedWindow(title: "Flightona Web - Launch readiness - src/App.tsx", bounds: .init(x: 0, y: 0, width: 1200, height: 900)),
        appName: "Codex",
        session: nil,
        now: Date(timeIntervalSince1970: 0)
    )

    #expect(context.projectName == "Flightona Web")
    #expect(context.chatTitle == "Launch readiness")
    #expect(context.filePath == "src/App.tsx")
    #expect(context.noteKindLabel == "File note")
}

@Test func promptFormatterOnlyIncludesSelectedBlocks() {
    let context = CodexContext.fallback(now: Date(timeIntervalSince1970: 0))
    var note = ContextNote.empty(context: context, now: Date(timeIntervalSince1970: 0))
    note.body = "Internal detail"
    note.todos = [
        NoteTodo(text: "Open task", isDone: false),
        NoteTodo(text: "Done task", isDone: true)
    ]
    note.reminders = [NoteReminder(text: "Follow up", dueText: "Tomorrow")]

    let prompt = PromptFormatter.format(note: note, includeBody: false, includeTodos: true, includeReminders: false)

    #expect(!prompt.contains("Internal detail"))
    #expect(prompt.contains("Open task"))
    #expect(!prompt.contains("Done task"))
    #expect(!prompt.contains("Follow up"))
}

@Test func promptFormatterOnlyIncludesSelectedTodoAndReminderItems() {
    let context = CodexContext.fallback(now: Date(timeIntervalSince1970: 0))
    var note = ContextNote.empty(context: context, now: Date(timeIntervalSince1970: 0))
    let selectedTodo = NoteTodo(text: "Send this todo")
    let skippedTodo = NoteTodo(text: "Keep this todo private")
    let selectedReminder = NoteReminder(text: "Send this follow-up", dueText: "Friday")
    let skippedReminder = NoteReminder(text: "Keep this follow-up private", dueText: "Later")
    note.todos = [selectedTodo, skippedTodo]
    note.reminders = [selectedReminder, skippedReminder]

    let prompt = PromptFormatter.format(
        note: note,
        includeBody: false,
        includeTodos: true,
        includeReminders: true,
        selectedTodoIDs: [selectedTodo.id],
        selectedReminderIDs: [selectedReminder.id]
    )

    #expect(prompt.contains("Send this todo"))
    #expect(!prompt.contains("Keep this todo private"))
    #expect(prompt.contains("Send this follow-up"))
    #expect(!prompt.contains("Keep this follow-up private"))
}

@Test func appShortcutDefaultDisplaysAndMatchesCarbonModifiers() {
    let shortcut = AppShortcut.default

    #expect(shortcut.keyCode == UInt32(kVK_ANSI_N))
    #expect(shortcut.displayName == "Control-Option-N")
    #expect(shortcut.carbonModifiers & UInt32(controlKey) != 0)
    #expect(shortcut.carbonModifiers & UInt32(optionKey) != 0)
    #expect(shortcut.carbonModifiers & UInt32(cmdKey) == 0)
}

@Test func storageKeyIncludesProjectPathToAvoidRelativeFileCollisions() {
    let first = CodexContext(
        projectName: "app",
        projectPath: "/work/first",
        chatTitle: nil,
        chatId: nil,
        filePath: "src/App.tsx",
        sourceAppName: "Codex",
        sourceWindowTitle: nil,
        detectionSummary: "Test",
        detectedAt: Date(timeIntervalSince1970: 0)
    )
    let second = CodexContext(
        projectName: "app",
        projectPath: "/work/second",
        chatTitle: nil,
        chatId: nil,
        filePath: "src/App.tsx",
        sourceAppName: "Codex",
        sourceWindowTitle: nil,
        detectionSummary: "Test",
        detectedAt: Date(timeIntervalSince1970: 0)
    )

    #expect(first.storageKey != second.storageKey)
}

@Test func sessionReaderUsesLatestUserSessionAndSkipsSubagents() throws {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    let sessions = root.appendingPathComponent("sessions/2026/05/26", isDirectory: true)
    try FileManager.default.createDirectory(at: sessions, withIntermediateDirectories: true)

    let parentId = "parent-session"
    let subagentId = "subagent-session"
    let index = """
    {"id":"\(parentId)","thread_name":"Add internal notes","updated_at":"2026-05-26T06:10:12.718199Z"}
    {"id":"\(subagentId)","thread_name":"Review UI","updated_at":"2026-05-26T06:56:08.732814Z"}
    """
    try index.write(to: root.appendingPathComponent("session_index.jsonl"), atomically: true, encoding: .utf8)

    let parentMeta = #"{"timestamp":"2026-05-26T06:10:07.407Z","type":"session_meta","payload":{"id":"parent-session","cwd":"/Users/example/demos","thread_source":"user"}}"#
    let subagentMeta = #"{"timestamp":"2026-05-26T06:56:07.407Z","type":"session_meta","payload":{"id":"subagent-session","cwd":"/Users/example/wrong","thread_source":"subagent"}}"#
    let parentBody = """
    \(parentMeta)
    {"timestamp":"2026-05-26T06:11:00.000Z","type":"response_item","payload":{"type":"function_call","name":"exec_command","arguments":"{\\"cmd\\":\\"sed -n '1,80p' /Users/example/demos/Sources/App/ContentView.swift\\"}"}}
    """
    try parentBody.write(to: sessions.appendingPathComponent("rollout-\(parentId).jsonl"), atomically: true, encoding: .utf8)
    try subagentMeta.write(to: sessions.appendingPathComponent("rollout-\(subagentId).jsonl"), atomically: true, encoding: .utf8)

    let snapshot = CodexSessionIndexReader(codexHome: root).latestUserSession()

    #expect(snapshot?.threadName == "Add internal notes")
    #expect(snapshot?.cwd == "/Users/example/demos")
    #expect(snapshot?.recentFilePath == "Sources/App/ContentView.swift")
}

@Test func detectorUsesSessionRecentFileWhenWindowTitleHasNoFile() {
    let session = CodexSessionSnapshot(
        id: "build-notes-session",
        threadName: "Build notes",
        cwd: "/Users/example/CodexContextNotes",
        recentFilePath: "Sources/CodexContextNotes/Views/NotesPanelView.swift",
        updatedAt: Date(timeIntervalSince1970: 0)
    )

    let context = CodexContextDetector.context(
        from: DetectedWindow(title: "Codex", bounds: .init(x: 0, y: 0, width: 1200, height: 900)),
        appName: "Codex",
        session: session,
        now: Date(timeIntervalSince1970: 0)
    )

    #expect(context.projectName == "CodexContextNotes")
    #expect(context.chatTitle == "Build notes")
    #expect(context.filePath == "Sources/CodexContextNotes/Views/NotesPanelView.swift")
    #expect(context.detectionSummary == "Latest Codex file reference")
}

@Test func detectorUsesActiveChatTitleForChatScopedNotes() {
    let session = CodexSessionSnapshot(
        id: "active-session",
        threadName: "Launch readiness",
        cwd: "/Users/example/Flightona",
        recentFilePath: "Sources/App.swift",
        updatedAt: Date(timeIntervalSince1970: 0)
    )

    let context = CodexContextDetector.context(
        fromActiveChatTitle: "Launch readiness",
        projectName: "Flightona",
        appName: "Codex",
        session: session,
        now: Date(timeIntervalSince1970: 0)
    )

    #expect(context.projectName == "Flightona")
    #expect(context.projectPath == "/Users/example/Flightona")
    #expect(context.chatTitle == "Launch readiness")
    #expect(context.chatId == "active-session")
    #expect(context.filePath == nil)
    #expect(context.noteKindLabel == "Chat note")
    #expect(context.detectionSummary == "Active Codex chat")
}
