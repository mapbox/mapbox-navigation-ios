import CoreLocation
import MapboxDirections

/// A tuple that pairs an array of coordinates with the level of
/// traffic congestion along these coordinates.
typealias CongestionSegment = ([CLLocationCoordinate2D], CongestionLevel)
