import Combine
import Foundation
import MapboxCommon_Private

protocol FeedbackEventsObserver {
    var navigationFeedbackPublisher: AnyPublisher<NavigationHistoryEvents.NavigationFeedback, Never> { get }

    func refreshSubscription()
}

final class FeedbackEventsObserverImpl: NSObject, FeedbackEventsObserver {
    private let navigationFeedbackSubject = PassthroughSubject<NavigationHistoryEvents.NavigationFeedback, Never>()
    var navigationFeedbackPublisher: AnyPublisher<NavigationHistoryEvents.NavigationFeedback, Never> {
        navigationFeedbackSubject.eraseToAnyPublisher()
    }

    private var eventsAPI: EventsService?
    private let options: MapboxCopilot.Options
    private var log: MapboxCopilot.Log? {
        options.log
    }

    init(options: MapboxCopilot.Options) {
        self.options = options

        super.init()
        refreshSubscription()
    }

    func refreshSubscription() {
        let sdkInformation = options.feedbackEventsSdkInformation
        let options = EventsServerOptions(
            sdkInformation: sdkInformation,
            deferredDeliveryServiceOptions: nil
        )
        eventsAPI = EventsService.getOrCreate(for: options)
        eventsAPI?.registerObserver(for: self)
    }

    private func parseEvent(_ attributes: [String: Any]) {
        switch attributes["event"] as? String {
        case "navigation.feedback":
            parseNavigationFeedbackEvent(attributes)
        default:
            log?("Skipping unknown event with attributes: \(attributes)")
        }
    }

    private func parseNavigationFeedbackEvent(_ attributes: [String: Any]) {
        guard let rawFeedbackId = attributes["feedbackId"],
              let rawFeedbackType = attributes["feedbackType"],
              let rawLatitude = attributes["lat"],
              let rawLongitude = attributes["lng"]
        else {
            assertionFailure("Failed to parse navigation feedback event")
            log?("Failed to fetch required fields for navigation feedback event")
            return
        }

        do {
            let typeConverter = TypeConverter()
            let feedbackId = try typeConverter.convert(from: rawFeedbackId, to: String.self)
            let feedbackType = try typeConverter.convert(from: rawFeedbackType, to: String.self)
            let latitude = try typeConverter.convert(from: rawLatitude, to: Double.self)
            let longitude = try typeConverter.convert(from: rawLongitude, to: Double.self)
            let feedbackSubtype: [String] = try attributes["feedbackSubType"].map {
                try typeConverter.convert(from: $0, to: [String].self)
            } ?? []
            let event = NavigationHistoryEvents.NavigationFeedback(
                payload: .init(
                    feedbackId: feedbackId,
                    type: feedbackType,
                    subtype: feedbackSubtype,
                    coordinate: .init(.init(latitude: latitude, longitude: longitude))
                )
            )
            navigationFeedbackSubject.send(event)
        } catch {
            assertionFailure("Failed to parse navigation feedback event")
        }
    }
}

extension FeedbackEventsObserverImpl: EventsServiceObserver {
    func didEncounterError(forError error: EventsServiceError, events: Any) {
        let eventsDescription = (events as? [[String: Any]])?.description ?? ""
        log?("Events Service did encounter error: \(error.message). Events: \(eventsDescription)")
    }

    func didSendEvents(forEvents events: Any) {
        guard let events = events as? [[String: Any]] else {
            assertionFailure("Failed to parse navigation feedback event.")
            return
        }
        for event in events {
            parseEvent(event)
        }
    }
}
