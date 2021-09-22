import Foundation

/**
 Feedback event that can be created using `NavigationEventsManager.createFeedback()`.
 Use `NavigationEventsManager.sendActiveNavigationFeedback(_:type:description:)` to send it to the server.
 Conforms to the `Codable` protocol, so the application can store the event persistently.
 */
public class FeedbackEvent: Codable {
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
    
    /// :nodoc:
    public var contents: [String: Any] {
        coreEvent.eventDictionary
    }
}
