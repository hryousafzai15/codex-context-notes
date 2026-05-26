import Foundation

struct CodexSessionSnapshot: Equatable {
    var id: String
    var threadName: String
    var cwd: String?
    var recentFilePath: String?
    var updatedAt: Date
}

final class CodexSessionIndexReader {
    private let codexHome: URL
    private var sessionFileCache: [String: URL]?

    init(codexHome: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".codex")) {
        self.codexHome = codexHome
    }

    func prewarm() {
        _ = sessionFileURL(for: "")
    }

    func latestUserSession(includeRecentFile: Bool = true) -> CodexSessionSnapshot? {
        let indexURL = codexHome.appendingPathComponent("session_index.jsonl")
        guard let lines = try? String(contentsOf: indexURL, encoding: .utf8)
            .split(separator: "\n")
            .suffix(80)
            .reversed() else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds

        for line in lines {
            guard let data = line.data(using: .utf8),
                  let entry = try? decoder.decode(SessionIndexEntry.self, from: data),
                  let snapshot = snapshot(for: entry, includeRecentFile: includeRecentFile) else {
                continue
            }

            return snapshot
        }

        return nil
    }

    func userSession(matchingThreadName threadName: String) -> CodexSessionSnapshot? {
        let normalizedName = threadName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedName.isEmpty else {
            return nil
        }

        let indexURL = codexHome.appendingPathComponent("session_index.jsonl")
        guard let lines = try? String(contentsOf: indexURL, encoding: .utf8)
            .split(separator: "\n")
            .suffix(300)
            .reversed() else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds

        for line in lines {
            guard let data = line.data(using: .utf8),
                  let entry = try? decoder.decode(SessionIndexEntry.self, from: data),
                  entry.threadName == normalizedName,
                  let snapshot = snapshot(for: entry, includeRecentFile: false) else {
                continue
            }

            return snapshot
        }

        return nil
    }

    private func snapshot(for entry: SessionIndexEntry, includeRecentFile: Bool) -> CodexSessionSnapshot? {
        guard let meta = sessionMeta(for: entry.id),
              meta.threadSource != "subagent" else {
            return nil
        }

        let sessionFile = includeRecentFile ? sessionFileURL(for: entry.id) : nil
        return CodexSessionSnapshot(
            id: entry.id,
            threadName: entry.threadName,
            cwd: meta.cwd,
            recentFilePath: sessionFile.flatMap { recentFilePath(in: $0, cwd: meta.cwd) },
            updatedAt: entry.updatedAt
        )
    }

    private func sessionMeta(for id: String) -> SessionMetaPayload? {
        guard let fileURL = sessionFileURL(for: id),
              let firstLine = try? String(contentsOf: fileURL, encoding: .utf8).split(separator: "\n").first,
              let data = firstLine.data(using: .utf8),
              let envelope = try? JSONDecoder().decode(SessionMetaEnvelope.self, from: data),
              envelope.type == "session_meta" else {
            return nil
        }
        return envelope.payload
    }

    private func sessionFileURL(for id: String) -> URL? {
        if let sessionFileCache {
            return sessionFileCache[id]
        }

        let sessionsURL = codexHome.appendingPathComponent("sessions")
        guard let enumerator = FileManager.default.enumerator(at: sessionsURL, includingPropertiesForKeys: nil) else {
            return nil
        }

        var cache: [String: URL] = [:]
        for case let fileURL as URL in enumerator {
            let fileName = fileURL.lastPathComponent
            if let range = fileName.range(of: #"([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})"#, options: .regularExpression) {
                cache[String(fileName[range])] = fileURL
            } else if fileName.hasPrefix("rollout-"), fileName.hasSuffix(".jsonl") {
                let fallbackID = fileName
                    .replacingOccurrences(of: "rollout-", with: "")
                    .replacingOccurrences(of: ".jsonl", with: "")
                cache[fallbackID] = fileURL
            }
        }

        sessionFileCache = cache
        return cache[id]
    }

    private func recentFilePath(in sessionFile: URL, cwd: String?) -> String? {
        guard let text = try? String(contentsOf: sessionFile, encoding: .utf8) else {
            return nil
        }

        let cwdPrefix = cwd.map { $0.hasSuffix("/") ? $0 : $0 + "/" }
        let extensions = "(swift|tsx|ts|jsx|js|css|html|md|json|py|rb|go|rs|java|kt|c|cc|cpp|h|hpp|toml|yml|yaml)"
        let absolutePattern = #"(/Users/[A-Za-z0-9_ .~/-]+?\.EXT)"#.replacingOccurrences(of: "EXT", with: extensions)
        let relativePattern = #"((Sources|Tests|src|app|lib|docs|script)/[A-Za-z0-9_./~ -]+?\.EXT)"#.replacingOccurrences(of: "EXT", with: extensions)

        var candidates: [String] = []
        for pattern in [absolutePattern, relativePattern] {
            guard let regex = try? NSRegularExpression(pattern: pattern) else {
                continue
            }
            let range = NSRange(text.startIndex..<text.endIndex, in: text)
            for match in regex.matches(in: text, range: range) {
                guard let matchRange = Range(match.range(at: 1), in: text) else {
                    continue
                }
                let raw = String(text[matchRange])
                let normalized = normalizeCandidate(raw, cwdPrefix: cwdPrefix)
                if isUsefulFileCandidate(normalized) {
                    candidates.append(normalized)
                }
            }
        }

        return candidates.last
    }

    private func normalizeCandidate(_ raw: String, cwdPrefix: String?) -> String {
        var value = raw
            .replacingOccurrences(of: "\\/", with: "/")
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'` "))

        if let cwdPrefix, value.hasPrefix(cwdPrefix) {
            value.removeFirst(cwdPrefix.count)
        }
        return value
    }

    private func isUsefulFileCandidate(_ path: String) -> Bool {
        let ignoredExtensions = [".log", ".png", ".jpg", ".jpeg", ".gif"]
        if ignoredExtensions.contains(where: { path.lowercased().hasSuffix($0) }) {
            return false
        }
        let ignoredFragments = ["/.build/", "/dist/", "/.git/", "/node_modules/"]
        return !ignoredFragments.contains { path.contains($0) }
    }
}

private struct SessionIndexEntry: Decodable {
    var id: String
    var threadName: String
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case threadName = "thread_name"
        case updatedAt = "updated_at"
    }
}

private struct SessionMetaEnvelope: Decodable {
    var type: String
    var payload: SessionMetaPayload
}

private struct SessionMetaPayload: Decodable {
    var cwd: String?
    var threadSource: String?

    enum CodingKeys: String, CodingKey {
        case cwd
        case threadSource = "thread_source"
    }
}

private extension JSONDecoder.DateDecodingStrategy {
    static let iso8601WithFractionalSeconds = custom { decoder in
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) {
            return date
        }
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: value) {
            return date
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date")
    }
}
