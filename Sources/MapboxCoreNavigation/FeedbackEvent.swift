import Foundation

/**
 Feedback event that can be created using `NavigationEventsManager.createFeedback()`.
 Use `NavigationEventsManager.sendFeedback(_:type:description:)` to send it to the server.
 Conforms to the `Codable` protocol, so the application can store the event persistently.
 */
public class FeedbackEvent: Codable {
    let coreEvent: CoreFeedbackEvent
    
    init(eventDetails: NavigationEventDetails) {
        let dictionary = try? eventDetails.asDictionary()
        coreEvent = CoreFeedbackEvent(timestamp: Date(), eventDictionary: dictionary ?? [:])
    }
    
    func update(type: FeedbackType, source: FeedbackSource, description: String?) {
        coreEvent.eventDictionary["feedbackType"] = type.description

        // if there is a subtype for this event then append the subtype description to our list for this type of feedback
        if let subtypeDescription = type.subtypeDescription {
            var subtypeList = [String]()
            if let existingSubtypeList = coreEvent.eventDictionary["feedbackSubType"] as? [String] {
                subtypeList.append(contentsOf: existingSubtypeList)
            }

            if !subtypeList.contains(subtypeDescription) {
                subtypeList.append(subtypeDescription)
            }
            coreEvent.eventDictionary["feedbackSubType"] = subtypeList
        }
        coreEvent.eventDictionary["source"] = source.description
        coreEvent.eventDictionary["description"] = description
    }
}
