import Foundation

/**
 Feedback event that can be created using `NavigationEventsManager.createFeedback()`.
 Use `NavigationEventsManager.sendActiveNavigationFeedback(_:type:description:)` to send it to the server.
 Conforms to the `Codable` protocol, so the application can store the event persistently.
 */
public class FeedbackEvent: Codable {
    let contentType: FeedbackContent

    enum FeedbackContent: Codable {
        case common(FeedbackCommonEvent)
        case native(FeedbackMetadata)
    }

    convenience init(eventDetails: NavigationEventDetails) {
        self.init(contentType: .common(FeedbackCommonEvent(eventDetails: eventDetails)))
    }

    convenience init(metadata: FeedbackMetadata) {
        self.init(contentType: .native(metadata))
    }

    init(contentType: FeedbackContent) {
        self.contentType = contentType
    }

    /// :nodoc:
    public var contents: [String: Any] {
        switch contentType {
            case .common(let data):
                return data.contents
            case .native(let data):
                return data.contents
        }
    }
}

// To be removed after only NN Telemetry is used
class FeedbackCommonEvent: Codable {
    let coreEvent: CoreFeedbackEvent
    
    init(eventDetails: NavigationEventDetails) {
        let dictionary = try? eventDetails.asDictionary()
        if dictionary == nil { assertionFailure("NavigationEventDetails can not be serialized") }
        coreEvent = CoreFeedbackEvent(timestamp: Date(), eventDictionary: dictionary ?? [:])
    }
    
    func update(with type: FeedbackType, source: FeedbackSource = .user, description: String?) {
        let feedbackSubTypeKey = "feedbackSubType"
        coreEvent.eventDictionary["feedbackType"] = type.typeKey

        // if there is a subtype for this event then append the subtype description to our list for this type of feedback
        if let subtypeDescription = type.subtypeKey {
            var subtypeList = [String]()
            if let existingSubtypeList = coreEvent.eventDictionary[feedbackSubTypeKey] as? [String] {
                subtypeList.append(contentsOf: existingSubtypeList)
            }

            if !subtypeList.contains(subtypeDescription) {
                subtypeList.append(subtypeDescription)
            }
            coreEvent.eventDictionary[feedbackSubTypeKey] = subtypeList
        }
        coreEvent.eventDictionary["source"] = source.description
        coreEvent.eventDictionary["description"] = description
    }
    
    var contents: [String: Any] {
        coreEvent.eventDictionary
    }
}
