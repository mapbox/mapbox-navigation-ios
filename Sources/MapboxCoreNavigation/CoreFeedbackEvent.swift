import Foundation
import MapboxDirections
import Polyline

/**
 Feedback event that can be created using `NavigationEventsManager.createFeedback()`.
 Use `NavigationEventsManager.sendFeedback(_:type:description:) to send it to the server.`
 Conforms to the `Codable` protocol, so the application can store the event persistently.
 */
public class CoreFeedbackEvent: Hashable, Codable {
    /**
     Unique identifier of the feedback.
     */
    public var identifier = UUID()
    
    var timestamp: Date
    
    var eventDictionary: [String: Any]
    
    init(timestamp: Date, eventDictionary: [String: Any]) {
        self.timestamp = timestamp
        self.eventDictionary = eventDictionary
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier.hashValue)
    }
    
    public static func ==(lhs: CoreFeedbackEvent, rhs: CoreFeedbackEvent) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case eventDictionaryData
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        let eventDictionaryData = try container.decode(Data.self, forKey: .eventDictionaryData)
        eventDictionary = try JSONSerialization.jsonObject(with: eventDictionaryData) as? [String: Any] ?? [:]
    }
    
    public func encode(to encoder: Encoder) throws {
        var containter = encoder.container(keyedBy: CodingKeys.self)
        try containter.encode(identifier, forKey: .id)
        try containter.encode(timestamp, forKey: .timestamp)
        let eventDictionaryData = try JSONSerialization.data(withJSONObject: eventDictionary)
        try containter.encode(eventDictionaryData, forKey: .eventDictionaryData)
    }
}

public class FeedbackEvent: CoreFeedbackEvent {
    func update(type: FeedbackType, source: FeedbackSource, description: String?) {
        eventDictionary["feedbackType"] = type.description

        // if there is a subtype for this event then append the subtype description to our list for this type of feedback
        if let subtypeDescription = type.subtypeDescription {
            var subtypeList = [String]()
            if let existingSubtypeList = eventDictionary["feedbackSubType"] as? [String] {
                subtypeList.append(contentsOf: existingSubtypeList)
            }

            if !subtypeList.contains(subtypeDescription) {
                subtypeList.append(subtypeDescription)
            }
            eventDictionary["feedbackSubType"] = subtypeList
        }
        eventDictionary["source"] = source.description
        eventDictionary["description"] = description
    }
}

class RerouteEvent: CoreFeedbackEvent {
    func update(newRoute: Route) {
        if let geometry = newRoute.shape?.coordinates {
            eventDictionary["newGeometry"] = Polyline(coordinates: geometry).encodedPolyline
            eventDictionary["newDistanceRemaining"] = round(newRoute.distance)
            eventDictionary["newDurationRemaining"] = round(newRoute.expectedTravelTime)
        }
    }
}
