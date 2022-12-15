import MapboxDirections
import MapboxNavigationNative

extension MapboxDirections.AmenityType {
    
    init(_ native: MapboxNavigationNative.AmenityType) {
        switch native {
        case .undefined:
            self = .undefined
        case .gasStation:
            self = .gasStation
        case .electricChargingStation:
            self = .electricChargingStation
        case .toilet:
            self = .toilet
        case .coffee:
            self = .coffee
        case .restaurant:
            self = .restaurant
        case .snack:
            self = .snack
        case .ATM:
            self = .ATM
        case .info:
            self = .info
        case .babyCare:
            self = .babyCare
        case .facilitiesForDisabled:
            self = .facilitiesForDisabled
        case .shop:
            self = .shop
        case .telephone:
            self = .telephone
        case .hotel:
            self = .hotel
        case .hotspring:
            self = .hotSpring
        case .shower:
            self = .shower
        case .picnicShelter:
            self = .picnicShelter
        case .post:
            self = .post
        case .FAX:
            self = .fax
        @unknown default:
            self = .undefined
            Log.fault("Unexpected amenity type.", category: .navigation)
            assertionFailure("Unexpected amenity type.")
        }
    }
}
