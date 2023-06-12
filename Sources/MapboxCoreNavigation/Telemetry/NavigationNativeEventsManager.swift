import Foundation
import CoreLocation
import UIKit
@_implementationOnly import MapboxNavigationNative_Private
import MapboxCommon

class NavigationNativeEventsManager: NavigationTelemetryManager {
    var delaysEventFlushing = true

    private let navigator: CoreNavigator
    private let eventsMetadataProvider: EventsMetadataProvider
    private let telemetry: Telemetry

    var userInfo: [String : String?]? {
        didSet {
            eventsMetadataProvider.userInfo = userInfo
        }
    }

    required init(navigator: CoreNavigator) {
        self.navigator = navigator
        self.eventsMetadataProvider = navigator.makeEventsMetadataProvider()
        self.telemetry = navigator.makeTelemetry(eventsMetadataProvider: eventsMetadataProvider)
    }

    func createFeedback(screenshotOption: FeedbackScreenshotOption) -> FeedbackEvent? {
        let userFeedbackHandle = telemetry.startBuildUserFeedbackMetadata()
        let screenshot = createScreenshot(screenshotOption: screenshotOption)
        let feedbackMetadata = FeedbackMetadata(userFeedbackHandle: userFeedbackHandle, screenshot: screenshot)
        return FeedbackEvent(metadata: feedbackMetadata)
    }

    func sendActiveNavigationFeedback(_ feedback: FeedbackEvent,
                                      type: ActiveNavigationFeedbackType,
                                      description: String?,
                                      source: FeedbackSource,
                                      completionHandler: UserFeedbackCompletionHandler?) {
        guard case .native(let feedbackMetadata) = feedback.contentType,
              let userFeedbackMetadata = feedbackMetadata.userFeedbackMetadata else {
            completionHandler?(.failure(.invalidData))
            return
        }

        let userFeedback = makeUserFeedback(feedbackMetadata: feedbackMetadata,
                                            type: type,
                                            description: description,
                                            source: source)
        let callback = createNativeUserCallback(feedbackMetadata: feedbackMetadata,
                                                completionHandler: completionHandler,
                                                type: type,
                                                description: description,
                                                source: source)
        telemetry.postUserFeedback(for: userFeedbackMetadata,
                                   userFeedback: userFeedback,
                                   callback: callback)
    }

    func sendPassiveNavigationFeedback(_ feedback: FeedbackEvent,
                                       type: PassiveNavigationFeedbackType,
                                       description: String?,
                                       source: FeedbackSource,
                                       completionHandler: UserFeedbackCompletionHandler?) {
        guard case .native(let feedbackMetadata) = feedback.contentType,
              let userFeedbackMetadata = feedbackMetadata.userFeedbackMetadata else {
            completionHandler?(.failure(.invalidData))
            return
        }

        let userFeedback = makeUserFeedback(feedbackMetadata: feedbackMetadata,
                                            type: type,
                                            description: description,
                                            source: source)
        let callback = createNativeUserCallback(feedbackMetadata: feedbackMetadata,
                                                completionHandler: completionHandler,
                                                type: type,
                                                description: description,
                                                source: source)
        telemetry.postUserFeedback(for: userFeedbackMetadata,
                                   userFeedback: userFeedback,
                                   callback: callback)
    }

    func sendCarPlayConnectEvent() {
        telemetry.postOuterDeviceEvent(for: .connected)
    }

    func sendCarPlayDisconnectEvent() {
        telemetry.postOuterDeviceEvent(for: .disconnected)
    }

    private func createNativeUserCallback(
        feedbackMetadata: FeedbackMetadata,
        completionHandler: UserFeedbackCompletionHandler?,
        type: FeedbackType,
        description: String?,
        source: FeedbackSource
    ) -> MapboxNavigationNative_Private.UserFeedbackCallback {
        guard let completionHandler = completionHandler else { return { _ in } }

        return { expected in
            if expected.isValue(), let location = expected.value {
                let userFeedback: MapboxCoreNavigation.UserFeedback = .init(
                    description: description,
                    type: type,
                    source: source,
                    screenshot: feedbackMetadata.screenshot,
                    location: location)
                completionHandler(.success(userFeedback))
            } else if expected.isError(), let errorString = expected.error {
                completionHandler(.failure(.failedToSend(reason: errorString as String)))
            }
        }
    }

    private func createScreenshot(screenshotOption: FeedbackScreenshotOption) -> String? {
        let screenshot: UIImage?
        switch screenshotOption {
            case .automatic:
                screenshot = captureScreen(scaledToFit: 250)
            case .custom(let customScreenshot):
                screenshot = customScreenshot
        }
        return screenshot?.jpegData(compressionQuality: 0.2)?.base64EncodedString()
    }

    private func makeUserFeedback(feedbackMetadata: FeedbackMetadata,
                                  type: FeedbackType,
                                  description: String?,
                                  source: FeedbackSource) -> MapboxNavigationNative_Private.UserFeedback {
        var feedbackSubType: [String] = []
        if let subtypeKey = type.subtypeKey {
            feedbackSubType.append(subtypeKey)
        }
        return .init(feedbackType: type.typeKey,
                     feedbackSubType: feedbackSubType,
                     description: description ?? "",
                     screenshot: .init(jpeg: nil, base64: feedbackMetadata.screenshot))
    }
}

extension String {
    func toDataRef() -> DataRef? {
        if let data = self.data(using: .utf8),
           let encodedData = Data(base64Encoded: data) {
            return .init(data: encodedData)
        }
        return nil
    }
}
