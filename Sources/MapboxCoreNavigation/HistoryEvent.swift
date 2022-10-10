import Foundation
import CoreLocation

/// Base class for history events produced by `HistoryFileReader`
public class HistoryEvent {
    /// Point in time when this event occured.
    public let timestamp: TimeInterval
    
    init(timestamp: TimeInterval) {
        self.timestamp = timestamp
    }
}

/// History event of when route was set.
public class HistorySetRoute: HistoryEvent {
    /// `IndexedRouteResponse` that was set.
    public let routeResponse: IndexedRouteResponse
    
    init(timestamp: TimeInterval, routeResponse: IndexedRouteResponse) {
        self.routeResponse = routeResponse
        super.init(timestamp: timestamp)
    }
}

/// History event of when location was updated.
public class HistoryUpdateLocation: HistoryEvent {
    /// `Location` being set.
    public let location: CLLocation
    
    init(timestamp: TimeInterval, location: CLLocation) {
        self.location = location
        super.init(timestamp: timestamp)
    }
}
