import Foundation

extension NavigationHistoryEvents {
    struct NavigationFeedback: Event {
        struct Payload: Encodable {
            var feedbackId: String
            var type: String
            var subtype: [String]
            var coordinate: Coordinate
        }

        let eventType = "nav_feedback_submitted"
        var payload: Payload
    }
}
