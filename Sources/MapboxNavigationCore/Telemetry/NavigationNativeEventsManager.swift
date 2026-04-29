import _MapboxNavigationHelpers
import CoreLocation
import Foundation
import MapboxCommon
import MapboxNavigationNative_Private
import UIKit

final class NavigationNativeEventsManager: NavigationTelemetryManager, Sendable {
    private let eventsMetadataProvider: EventsMetadataProvider
    @MainActor
    private let telemetry: Telemetry

    nonisolated var userInfo: [String: String?]? {
        get {
            eventsMetadataProvider.userInfo
        }
        set {
            eventsMetadataProvider.userInfo = newValue
        }
    }

    @MainActor
    init(eventsMetadataProvider: EventsMetadataProvider, telemetry: Telemetry) {
        self.eventsMetadataProvider = eventsMetadataProvider
        self.telemetry = telemetry
    }

    func createFeedback(screenshotOption: FeedbackScreenshotOption) async -> FeedbackEvent? {
        let userFeedbackMetadata = await MainActor.run {
            // `getMetadata()` should be called from the same thread as Telemetry was created
            // to avoid bindgen errors.
            // Currently, we use the main thread to work with Telemetry.
            telemetry.startBuildUserFeedbackMetadata().getMetadata()
        }
        let screenshot = await createScreenshot(screenshotOption: screenshotOption)
        let feedbackMetadata = FeedbackMetadata(userFeedbackMetadata: userFeedbackMetadata, screenshot: screenshot)
        return FeedbackEvent(metadata: feedbackMetadata)
    }

    func sendActiveNavigationFeedback(
        _ feedback: FeedbackEvent,
        type: ActiveNavigationFeedbackType,
        description: String?,
        source: FeedbackSource
    ) async throws -> UserFeedback {
        try await sendNavigationFeedback(
            feedback,
            type: type,
            description: description,
            source: source
        )
    }

    func sendPassiveNavigationFeedback(
        _ feedback: FeedbackEvent,
        type: PassiveNavigationFeedbackType,
        description: String?,
        source: FeedbackSource
    ) async throws -> UserFeedback {
        try await sendNavigationFeedback(
            feedback,
            type: type,
            description: description,
            source: source
        )
    }

    func sendNavigationFeedback(
        _ feedback: FeedbackEvent,
        type: FeedbackType,
        description: String?,
        source: FeedbackSource
    ) async throws -> UserFeedback {
        let feedbackMetadata = feedback.metadata
        guard let userFeedbackMetadata = feedbackMetadata.userFeedbackMetadata else {
            throw NavigationEventsManagerError.invalidData
        }

        let userFeedback = makeUserFeedback(
            feedbackMetadata: feedbackMetadata,
            type: type,
            description: description,
            source: source
        )
        let localTelemetry = await telemetry
        return try await withCheckedThrowingContinuation { continuation in
            localTelemetry.postUserFeedback(
                for: userFeedbackMetadata,
                userFeedback: userFeedback
            ) { expected in
                if expected.isValue(), let coordinate = expected.value {
                    let userFeedback: UserFeedback = .init(
                        description: description,
                        type: type,
                        source: source,
                        screenshot: feedbackMetadata.screenshot,
                        location: CLLocation(coordinate: coordinate.value)
                    )
                    continuation.resume(returning: userFeedback)
                } else if expected.isError(), let errorString = expected.error {
                    let error = NavigationEventsManagerError.failedToSend(reason: errorString as String)
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: NavigationEventsManagerError.failedToSend(reason: "Unknown"))
                }
            }
        }
    }

    func sendCarPlayConnectEvent() async {
        await telemetry.postOuterDeviceEvent(for: .connected)
    }

    func sendCarPlayDisconnectEvent() async {
        await telemetry.postOuterDeviceEvent(for: .disconnected)
    }

    private func createNativeUserCallback(
        feedbackMetadata: FeedbackMetadata,
        continuation: UnsafeContinuation<UserFeedback, Error>,
        type: FeedbackType,
        description: String?,
        source: FeedbackSource
    ) -> MapboxNavigationNative_Private.UserFeedbackCallback {
        return { expected in
            if expected.isValue(), let coordinate = expected.value {
                let userFeedback: UserFeedback = .init(
                    description: description,
                    type: type,
                    source: source,
                    screenshot: feedbackMetadata.screenshot,
                    location: CLLocation(coordinate: coordinate.value)
                )
                continuation.resume(returning: userFeedback)
            } else if expected.isError(), let errorString = expected.error {
                continuation.resume(throwing: NavigationEventsManagerError.failedToSend(reason: errorString as String))
            }
        }
    }

    private func createScreenshot(screenshotOption: FeedbackScreenshotOption) async -> String? {
        let screenshot: UIImage? = switch screenshotOption {
        case .automatic:
            await captureScreen(scaledToFit: 250)
        case .custom(let customScreenshot):
            customScreenshot
        }
        return screenshot?.jpegData(compressionQuality: 0.2)?.base64EncodedString()
    }

    private func makeUserFeedback(
        feedbackMetadata: FeedbackMetadata,
        type: FeedbackType,
        description: String?,
        source: FeedbackSource
    ) -> MapboxNavigationNative_Private.UserFeedback {
        var feedbackSubType: [String] = []
        if let subtypeKey = type.subtypeKey {
            feedbackSubType.append(subtypeKey)
        }
        return .init(
            feedbackType: type.typeKey,
            feedbackSubType: feedbackSubType,
            description: description ?? "",
            screenshot: .init(jpeg: nil, base64: feedbackMetadata.screenshot)
        )
    }
}

extension String {
    func toDataRef() -> DataRef? {
        if let data = data(using: .utf8),
           let encodedData = Data(base64Encoded: data)
        {
            return .init(data: encodedData)
        }
        return nil
    }
}
