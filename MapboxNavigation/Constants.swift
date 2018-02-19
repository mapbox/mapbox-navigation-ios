import Foundation
import MapboxDirections

typealias CongestionSegment = ([CLLocationCoordinate2D], CongestionLevel)

/**
 Line width base values used at zoom levels.
 */
public let MBRoutelineWidthAtZoomLevels: [Int: MGLStyleValue<NSNumber>] = [
    10: MGLStyleValue(rawValue: 8),
    13: MGLStyleValue(rawValue: 9),
    16: MGLStyleValue(rawValue: 11),
    19: MGLStyleValue(rawValue: 22),
    22: MGLStyleValue(rawValue: 28)
]

/**
 The minium distance remaining on a route before overhead zooming is stopped.
 */
public var NavigationMapViewMinimumDistanceForOverheadZooming: CLLocationDistance = 200

/**
 Attribute name for the route line that is used for identifying whether a RouteLeg is the current active leg.
 */
public let MBCurrentLegAttribute = "isCurrentLeg"

/**
 Attribute name for the route line that is used for identifying different `CongestionLevel` along the route.
 */
public let MBCongestionAttribute = "congestion"
