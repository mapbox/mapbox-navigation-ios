import Foundation
import MapboxDirections
import MapboxNavigationNative

extension RestStop {
    init?(_ serviceArea: ServiceAreaInfo) {
        let amenities: [MapboxDirections.Amenity] = serviceArea.amenities.map { amenity in
            Amenity(
                type: AmenityType(amenity.type),
                name: amenity.name,
                brand: amenity.brand
            )
        }

        switch serviceArea.type {
        case .restArea:
            self.init(type: .restArea, name: serviceArea.name, amenities: amenities)
        case .serviceArea:
            self.init(type: .serviceArea, name: serviceArea.name, amenities: amenities)
        @unknown default:
            assertionFailure("Unknown ServiceAreaInfo type.")
            return nil
        }
    }
}
