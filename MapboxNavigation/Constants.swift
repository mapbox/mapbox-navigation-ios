import Foundation
import MapboxDirections

typealias CongestionSegment = ([CLLocationCoordinate2D], CongestionLevel)

/**
 A stop dictionary representing the default line widths of the route line by zoom level when `NavigationMapViewDelegate.navigationMapView(_:routeStyleLayerWithIdentifier:source:)` is undefined.
 
 You may use this constant in your implementation of `NavigationMapViewDelegate.navigationMapView(_:routeStyleLayerWithIdentifier:source:)` if you want to keep the default line widths but customize other aspects of the route line.
 */
public let MBRouteLineWidthByZoomLevel: [Int: MGLStyleValue<NSNumber>] = [
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
