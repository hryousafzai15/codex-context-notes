import Foundation

final class NotesRepository {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileURL: URL? = nil) {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("CodexContextNotes", isDirectory: true)
        self.fileURL = fileURL ?? baseURL.appendingPathComponent("notes.json")

        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    func note(for context: CodexContext) -> ContextNote {
        var notes = loadAll()
        if let existing = notes[context.storageKey] {
            var updated = existing
            updated.context = context
            return updated
        }
        let note = ContextNote.empty(context: context)
        notes[context.storageKey] = note
        saveAll(notes)
        return note
    }

    func save(_ note: ContextNote) {
        var notes = loadAll()
        var updated = note
        updated.updatedAt = Date()
        notes[updated.context.storageKey] = updated
        saveAll(notes)
    }

    func loadAll() -> [String: ContextNote] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return [:]
        }

        do {
            let data = try Data(contentsOf: fileURL)
            return try decoder.decode([String: ContextNote].self, from: data)
        } catch {
            return [:]
        }
    }

    private func saveAll(_ notes: [String: ContextNote]) {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try encoder.encode(notes)
            try data.write(to: fileURL, options: [.atomic])
        } catch {
            assertionFailure("Unable to save notes: \(error)")
        }
    }
}
