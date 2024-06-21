import Foundation

/// Type of the ``Amenity``.
public enum AmenityType: String, Codable, Equatable, Sendable {
    /// Undefined amenity type.
    case undefined

    /// Gas station amenity type.
    case gasStation = "gas_station"

    /// Electric charging station amenity type.
    case electricChargingStation = "electric_charging_station"

    /// Toilet amenity type.
    case toilet

    /// Coffee amenity type.
    case coffee

    /// Restaurant amenity type.
    case restaurant

    /// Snack amenity type.
    case snack

    /// ATM amenity type.
    case ATM

    /// Info amenity type.
    case info

    /// Baby care amenity type.
    case babyCare = "baby_care"

    /// Facilities for disabled amenity type.
    case facilitiesForDisabled = "facilities_for_disabled"

    /// Shop amenity type.
    case shop

    /// Telephone amenity type.
    case telephone

    /// Hotel amenity type.
    case hotel

    /// Hot spring amenity type.
    case hotSpring = "hotspring"

    /// Shower amenity type.
    case shower

    /// Picnic shelter amenity type.
    case picnicShelter = "picnic_shelter"

    /// Post amenity type.
    case post

    /// Fax amenity type.
    case fax
}
