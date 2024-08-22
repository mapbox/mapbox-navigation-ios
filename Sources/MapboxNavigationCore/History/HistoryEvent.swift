import CoreLocation
import Foundation
import MapboxNavigationNative

/// Describes history events produced by ``HistoryReader``
public protocol HistoryEvent: Equatable, Sendable {
    /// Point in time when this event occured.
    var timestamp: TimeInterval { get }
}

extension HistoryEvent {
    func compare(to other: any HistoryEvent) -> Bool {
        guard let other = other as? Self else {
            return false
        }
        return self == other
    }
}

/// History event of when route was set.
public struct RouteAssignmentHistoryEvent: HistoryEvent {
    public let timestamp: TimeInterval
    /// ``NavigationRoutes`` that was set.
    public let navigationRoutes: NavigationRoutes
}

/// History event of when location was updated.
public struct LocationUpdateHistoryEvent: HistoryEvent {
    /// Point in time when this event occured.
    ///
    /// This illustrates the moment when history event was recorded. This may differ from
    /// ``LocationUpdateHistoryEvent/location``'s `timestamp` since it displays when particular location was reached.
    public let timestamp: TimeInterval
    /// `CLLocation` being set.
    public let location: CLLocation
}

/// History event of unrecognized type.
///
/// Such events usually mean that this type of events is not yet supported or this one is for service use only.
public class UnknownHistoryEvent: HistoryEvent, @unchecked Sendable {
    public static func == (lhs: UnknownHistoryEvent, rhs: UnknownHistoryEvent) -> Bool {
        return lhs.timestamp == rhs.timestamp
    }

    public let timestamp: TimeInterval

    init(timestamp: TimeInterval) {
        self.timestamp = timestamp
    }
}

final class StatusUpdateHistoryEvent: UnknownHistoryEvent, @unchecked Sendable {
    let monotonicTimestamp: TimeInterval
    let status: NavigationStatus

    init(timestamp: TimeInterval, monotonicTimestamp: TimeInterval, status: NavigationStatus) {
        self.monotonicTimestamp = monotonicTimestamp
        self.status = status

        super.init(timestamp: timestamp)
    }
}

/// History event being pushed by the user
///
/// Such events are created by calling ``HistoryRecording/pushHistoryEvent(type:jsonData:)``.
public struct UserPushedHistoryEvent: HistoryEvent {
    public let timestamp: TimeInterval
    /// The event type specified for this custom event.
    public let type: String
    /// The data value that contains a valid JSON attached to the event.
    ///
    /// This value was provided by user with `HistoryRecording.pushHistoryEvent` method's `dictionary` argument.
    public let properties: String

    init(timestamp: TimeInterval, type: String, properties: String) {
        self.type = type
        self.properties = properties
        self.timestamp = timestamp
    }
}
