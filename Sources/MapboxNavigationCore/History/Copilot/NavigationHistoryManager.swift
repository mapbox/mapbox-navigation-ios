import Combine
import Foundation

protocol NavigationHistoryManagerDelegate: AnyObject {
    func historyManager(_ historyManager: NavigationHistoryManager, didEncounterError error: CopilotError)
    func historyManager(
        _ historyManager: NavigationHistoryManager,
        didUploadHistoryForSession session: NavigationSession
    )
}

final class NavigationHistoryManager: ObservableObject, @unchecked Sendable {
    private enum RemovalPolicy {
        static let maxTimeIntervalToKeepHistory: TimeInterval = -24 * 60 * 60 // 1 day
    }

    private let localStorage: NavigationHistoryLocalStorageProtocol?
    private let uploader: NavigationHistoryUploaderProtocol
    private let log: MapboxCopilot.Log?

    weak var delegate: NavigationHistoryManagerDelegate?

    convenience init(options: MapboxCopilot.Options) {
        self.init(
            localStorage: NavigationHistoryLocalStorage(log: options.log),
            uploader: NavigationHistoryUploader(options: options),
            log: options.log
        )
    }

    init(
        localStorage: NavigationHistoryLocalStorageProtocol?,
        uploader: NavigationHistoryUploaderProtocol,
        log: MapboxCopilot.Log?
    ) {
        self.localStorage = localStorage
        self.uploader = uploader
        self.log = log

        loadAndUploadPreviousSessions()
    }

    func loadAndUploadPreviousSessions() {
        guard let localStorage else { return }
        Task.detached { [weak self] in
            guard let self else { return }
            let restoredSessions = localStorage.savedSessions()
                .filter { session in
                    if self.shouldRetryUpload(session) {
                        return true
                    } else {
                        localStorage.deleteSession(session)
                        return false
                    }
                }
                .sorted(by: { $0.startedAt > $1.startedAt })

            let removalDeadline = Date().addingTimeInterval(RemovalPolicy.maxTimeIntervalToKeepHistory)
            NavigationHistoryLocalStorage.removeExpiredMetadataFiles(deadline: removalDeadline)
            for session in restoredSessions {
                await upload(session)
            }
        }
    }

    func complete(_ session: NavigationSession) async {
        var session = session
        session.state = .local
        localStorage?.saveSession(session)
        await upload(session)
    }

    func update(_ session: NavigationSession) {
        localStorage?.saveSession(session)
    }

    private func upload(_ session: NavigationSession) async {
        var session = session
        session.state = .uploading

        do {
            try await uploader.upload(session, log: log)
            delegate?.historyManager(self, didUploadHistoryForSession: session)
            localStorage?.deleteSession(session)
        } catch {
            // We will retry to upload the file on next launch
            session.state = .local
            delegate?.historyManager(self, didEncounterError: .history(
                .failedAttachmentsUpload,
                session: session,
                userInfo: ["error": error.localizedDescription]
            ))
            localStorage?.saveSession(session)
        }
    }

    private func shouldRetryUpload(_ session: NavigationSession) -> Bool {
        guard let url = session.lastHistoryFileUrl, FileManager.default.fileExists(atPath: url.path) else {
            delegate?.historyManager(self, didEncounterError: .history(.missingLastHistoryFile, session: session))
            return false
        }
        guard session.startedAt.timeIntervalSinceNow < RemovalPolicy.maxTimeIntervalToKeepHistory else {
            // File is too old to be uploaded, we will delete it
            return false
        }
        switch session.state {
        case .local, .uploading:
            return true
        case .inProgress:
            // Session might be in `.inProgress` state if it wasn't finished properly (i.e. a crash happened)
            // In this case we don't want to upload a potentially corrupted file
            return false
        }
    }
}
