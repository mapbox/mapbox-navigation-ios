import CoreLocation
import Foundation
import MapboxDirections
import MapboxNavigationNative

/// ``RouteAlert`` encapsulates information about various incoming events. Common attributes like location, distance to
/// the event, length and other is provided for each POI, while specific meta data is supplied via ``roadObject``
/// property.
public struct RouteAlert: Equatable, Sendable {
    /// Road object which describes upcoming route alert.
    public let roadObject: RoadObject

    /// Distance from current position to alert, meters.
    ///
    /// This value can be negative if it is a spanned alert and we are somewhere in the middle of it.
    public let distanceToStart: CLLocationDistance

    init(_ native: UpcomingRouteAlert, distanceToStart: CLLocationDistance) {
        self.roadObject = RoadObject(native.roadObject)
        self.distanceToStart = distanceToStart
    }
}
