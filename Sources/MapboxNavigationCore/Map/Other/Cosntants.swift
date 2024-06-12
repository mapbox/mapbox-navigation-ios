import CoreLocation

/// A stop dictionary representing the default line widths of the route line by zoom level.
public let RouteLineWidthByZoomLevel: [Double: Double] = [
    10.0: 8.0,
    13.0: 9.0,
    16.0: 11.0,
    19.0: 22.0,
    22.0: 28.0,
]

/// Attribute name for the route line that is used for identifying restricted areas along the route.
let RestrictedRoadClassAttribute = "isRestrictedRoad"

/// Attribute name for the route line that is used for identifying whether a RouteLeg is the current active leg.
let CurrentLegAttribute = "isCurrentLeg"

/// Attribute name for the route line that is used for identifying different `CongestionLevel` along the route.
let CongestionAttribute = "congestion"

/// The distance of fading color change between two different congestion level segments in meters.
let GradientCongestionFadingDistance: CLLocationDistance = 30.0
