import Foundation

protocol NavigationHistoryLocalStorageProtocol: Sendable {
    func savedSessions() -> [NavigationSession]
    func saveSession(_ session: NavigationSession)
    func deleteSession(_ session: NavigationSession)
}

/// Stores history files metadata
final class NavigationHistoryLocalStorage: NavigationHistoryLocalStorageProtocol, @unchecked Sendable {
    private static let storageUrl = FileManager.applicationSupportURL
        .appendingPathComponent("com.mapbox.Copilot")
        .appendingPathComponent("NavigationSessions")

    private let log: MapboxCopilot.Log?

    init(log: MapboxCopilot.Log?) {
        self.log = log
    }

    func savedSessions() -> [NavigationSession] {
        guard let enumerator = FileManager.default.enumerator(at: Self.storageUrl, includingPropertiesForKeys: nil)
        else {
            return []
        }

        let decoder = JSONDecoder()
        let fileUrls = enumerator.compactMap { (element: NSEnumerator.Element) -> URL? in element as? URL }

        var sessions = [NavigationSession]()
        for fileUrl in fileUrls {
            do {
                let data = try Data(contentsOf: fileUrl)
                let session = try decoder.decode(NavigationSession.self, from: data)
                sessions.append(session)
            } catch {
                log?("Failed to decode navigation session. Error: \(error). Path: \(fileUrl.absoluteString)")
                try? FileManager.default.removeItem(at: fileUrl)
            }
        }
        return sessions
    }

    func saveSession(_ session: NavigationSession) {
        let fileUrl = storageFileUrl(for: session)
        do {
            let data = try JSONEncoder().encode(session)
            let parentDirectory = fileUrl.deletingLastPathComponent()
            if FileManager.default.fileExists(atPath: parentDirectory.path) == false {
                try FileManager.default.createDirectory(
                    at: parentDirectory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
            }
            try data.write(to: fileUrl, options: .atomic)
        } catch {
            log?("Failed to save navigation session. Error: \(error). Session id: \(session.id)")
        }
    }

    func deleteSession(_ session: NavigationSession) {
        do {
            try FileManager.default.removeItem(at: storageFileUrl(for: session))
            try session.deleteLastHistoryFile()
        } catch {
            log?("Failed to delete navigation session. Error: \(error). Session id: \(session.id)")
        }
    }

    static func removeExpiredMetadataFiles(deadline: Date) {
        FileManager.default.removeFiles(in: storageUrl, createdBefore: deadline)
    }

    private func storageFileUrl(for session: NavigationSession) -> URL {
        return Self.storageUrl.appendingPathComponent(session.id).appendingPathExtension("json")
    }
}
