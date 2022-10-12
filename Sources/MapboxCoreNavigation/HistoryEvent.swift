import Foundation
import CoreLocation
import MapboxNavigationNative


/// Describes history events produced by `HistoryReader`
public protocol HistoryEvent {
    /// Point in time when this event occured.
    var timestamp: TimeInterval { get }
}

/// History event of when route was set.
public struct RouteAssignmentHistoryEvent: HistoryEvent {
    public let timestamp: TimeInterval
    /// `IndexedRouteResponse` that was set.
    public let routeResponse: IndexedRouteResponse
}

/// History event of when location was updated.
public struct LocationUpdateHistoryEvent: HistoryEvent {
    /// Point in time when this event occured.
    ///
    /// This illustrates the moment when history event was recorded. This may differ from `HistoryUpdateLocation.location.timestamp` since it displays when particular location was reached.
    public let timestamp: TimeInterval
    /// `Location` being set.
    public let location: CLLocation
}

/// History event of unrecognized type.
///
/// Such events usually mean that this type of events is not yet supported or this one is for service use only.
public class UnknownHistoryEvent: HistoryEvent {
    public let timestamp: TimeInterval
    
    init(timestamp: TimeInterval) {
        self.timestamp = timestamp
    }
}

internal class StatusUpdateHistoryEvent: UnknownHistoryEvent {
    let monotonicTimestamp: TimeInterval
    let status: NavigationStatus
    
    init(timestamp: TimeInterval, monotonicTimestamp: TimeInterval, status: NavigationStatus) {
        self.monotonicTimestamp = monotonicTimestamp
        self.status = status
    
        super.init(timestamp: timestamp)
    }
}

internal class PushRecordHistoryEvent: UnknownHistoryEvent {
    let type: String
    let properties: String
    
    init(timestamp: TimeInterval, type: String, properties: String) {
        self.type = type
        self.properties = properties
    
        super.init(timestamp: timestamp)
    }
}
