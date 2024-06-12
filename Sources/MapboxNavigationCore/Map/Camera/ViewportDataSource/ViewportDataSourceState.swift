import CoreLocation
import Foundation
import MapboxDirections
import Turf
import UIKit

struct ViewportDataSourceState: Equatable, Sendable {
    enum NavigationState: Equatable, Sendable {
        case passive
        case active(ActiveNavigationState)
    }

    struct ActiveNavigationState: Equatable, Sendable {
        var coordinatesToManeuver: [LocationCoordinate2D]
        var lookaheadDistance: LocationDistance
        var currentLegStepIndex: Int
        var currentLegSteps: [RouteStep]
        var isRouteComplete: Bool
        var remainingCoordinatesOnRoute: [LocationCoordinate2D]
        var transportType: TransportType
        var distanceRemainingOnStep: CLLocationDistance
    }

    var location: CLLocation?
    var heading: CLHeading?
    var navigationState: NavigationState
    var viewportPadding: UIEdgeInsets
}
