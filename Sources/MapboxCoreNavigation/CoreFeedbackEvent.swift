import Foundation
import MapboxDirections
import Polyline

class CoreFeedbackEvent: Hashable, Codable {
    let identifier: UUID
    var timestamp: Date
    
    var eventDictionary: [String: Any]
    
    var appMetadata: [String: String?]? = nil
    
    init(timestamp: Date, eventDictionary: [String: Any]) {
        self.timestamp = timestamp
        self.eventDictionary = eventDictionary
        identifier = UUID()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(identifier.hashValue)
    }
    
    static func ==(lhs: CoreFeedbackEvent, rhs: CoreFeedbackEvent) -> Bool {
        return lhs.identifier == rhs.identifier
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case eventDictionaryData
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        identifier = try container.decode(UUID.self, forKey: .id)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        let eventDictionaryData = try container.decode(Data.self, forKey: .eventDictionaryData)
        eventDictionary = try JSONSerialization.jsonObject(with: eventDictionaryData) as? [String: Any] ?? [:]
    }
    
    func encode(to encoder: Encoder) throws {
        var containter = encoder.container(keyedBy: CodingKeys.self)
        try containter.encode(identifier, forKey: .id)
        try containter.encode(timestamp, forKey: .timestamp)
        let eventDictionaryData = try JSONSerialization.data(withJSONObject: eventDictionary)
        try containter.encode(eventDictionaryData, forKey: .eventDictionaryData)
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
