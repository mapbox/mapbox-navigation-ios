import Foundation

enum EventKey: String {
    case event = "event"
    case created = "created"
    case feedbackId = "feedbackId"
    case locationsBefore = "locationsBefore"
    case locationsAfter = "locationsAfter"
    case payload = "payload"
    case customEventVersion = "1.2.3"
}

enum EventType: String {
    case turnstile = "appUserTurnstile"
    case depart = "navigation.depart"
    case arrive = "navigation.arrive"
    case cancel = "navigation.cancel"
    case feedback = "navigation.feedback"
    case reroute = "navigation.reroute"
    case carplayConnect = "navigation.carplay.connect"
    case carplayDisconnect = "navigation.carplay.disconnect"
    case routeRetrieval = "mobile.performance_trace"
    case freeDrive = "navigation.freeDrive"
    case customEvent = "navigation.customEvent"
}

// :nodoc:
public enum EventRating {
    public static let unrated = -1
    public static let topRated = 100
}
