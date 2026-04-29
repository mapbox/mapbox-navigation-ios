
import Foundation

/// A road classification according to the [Mapbox Streets
/// source](https://docs.mapbox.com/vector-tiles/reference/mapbox-streets-v8/#road) , version 8.
public enum MapboxStreetsRoadClass: String, Codable, Equatable, Sendable {
    /// High-speed, grade-separated highways
    case motorway
    /// Link roads/lanes/ramps connecting to motorways
    case motorwayLink = "motorway_link"
    /// Important roads that are not motorways.
    case trunk
    /// Link roads/lanes/ramps connecting to trunk roads
    case trunkLink = "trunk_link"
    /// A major highway linking large towns.
    case primary
    /// Link roads/lanes connecting to primary roads
    case primaryLink = "primary_link"
    /// A highway linking large towns.
    case secondary
    /// Link roads/lanes connecting to secondary roads
    case secondaryLink = "secondary_link"
    /// A road linking small settlements, or the local centres of a large town or city.
    case tertiary
    /// Link roads/lanes connecting to tertiary roads
    case tertiaryLink = "tertiary_link"
    /// Standard unclassified, residential, road, and living_street road types
    case street
    /// Streets that may have limited or no access for motor vehicles.
    case streetLimited = "street_limited"
    /// Includes pedestrian streets, plazas, and public transportation platforms.
    case pedestrian
    /// Includes motor roads under construction (but not service roads, paths, etc.
    case construction
    /// Roads mostly for agricultural and forestry use etc.
    case track
    /// Access roads, alleys, agricultural tracks, and other services roads. Also includes parking lot aisles, public &
    /// private driveways.
    case service
    /// Those that serves automobiles and no or unspecified automobile service.
    case ferry
    /// Foot paths, cycle paths, ski trails.
    case path
    /// Railways, including mainline, commuter rail, and rapid transit.
    case majorRail = "major_rail"
    /// Includes light rail & tram lines.
    case minorRail = "minor_rail"
    /// Yard and service railways.
    case serviceRail = "service_rail"
    /// Ski lifts, gondolas, and other types of aerialway.
    case aerialway
    /// The approximate centerline of a golf course hole
    case golf
    /// Undefined
    case undefined
}
