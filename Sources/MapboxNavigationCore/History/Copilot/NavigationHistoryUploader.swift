import Foundation
import UIKit

protocol NavigationHistoryUploaderProtocol {
    func upload(_: NavigationSession, log: MapboxCopilot.Log?) async throws
}

final class NavigationHistoryUploader: NavigationHistoryUploaderProtocol {
    private let attachmentsUploader: AttachmentsUploaderImpl

    init(options: MapboxCopilot.Options) {
        self.attachmentsUploader = AttachmentsUploaderImpl(options: options)
    }

    @MainActor
    func upload(_ session: NavigationSession, log: MapboxCopilot.Log?) async throws {
        var backgroundTask: UIBackgroundTaskIdentifier?
        let completeBackgroundTask = {
            guard let guardedBackgroundTask = backgroundTask else { return }
            Task {
                UIApplication.shared.endBackgroundTask(guardedBackgroundTask)
            }
            backgroundTask = nil
        }
        backgroundTask = UIApplication.shared.beginBackgroundTask(
            withName: "Uploading session",
            expirationHandler: completeBackgroundTask
        )
        defer { completeBackgroundTask() }
        try await uploadWithinTask(session, log: log)
    }

    @MainActor
    private func uploadWithinTask(_ session: NavigationSession, log: MapboxCopilot.Log?) async throws {
        do {
            try await uploadToAttachments(session: session, log: log)
            log?(
                "History session uploaded. Type: \(session.sessionType.metadataValue)." +
                    "Session id: \(session.id)"
            )
        } catch {
            log?(
                "Failed to upload session. Error: \(error). Session id: \(session.id). " +
                    "Start time: \(session.startedAt)"
            )
            throw error
        }
    }

    @MainActor
    private func uploadToAttachments(session: NavigationSession, log: MapboxCopilot.Log?) async throws {
        let attachment: AttachmentArchive
        do {
            attachment = try NavigationHistoryAttachmentProvider.attachementArchive(for: session)
        } catch {
            log?("Incompatible attachments upload. Session id: \(session.id). Error: \(error)")
            throw error
        }

        do {
            try await attachmentsUploader.upload(accessToken: session.accessToken, archive: attachment)
        } catch {
            log?(
                "Failed to upload history to Attachments API. Error: \(error). Session id: \(session.id)" +
                    "Start time: \(session.startedAt)"
            )
            throw error
        }
    }
}
