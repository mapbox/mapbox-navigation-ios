import Foundation
import MapboxDirections
import Polyline

class CoreFeedbackEvent: Hashable {
    var id = UUID()
    
    var timestamp: Date
    
    var eventDictionary: [String: Any]
    
    init(timestamp: Date, eventDictionary: [String: Any]) {
        self.timestamp = timestamp
        self.eventDictionary = eventDictionary
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id.hashValue)
    }
    
    static func ==(lhs: CoreFeedbackEvent, rhs: CoreFeedbackEvent) -> Bool {
        return lhs.id == rhs.id
    }
}

class FeedbackEvent: CoreFeedbackEvent {
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
