
import Foundation
import MapboxNavigationNative
import MapboxDirections

extension RestStop {
    init(_ serviceArea: ServiceAreaInfo) {
        switch serviceArea.type {
        case .restArea:
            self.init(type: .restArea, name: serviceArea.name, amenities: [])
        case .serviceArea:
            self.init(type: .serviceArea, name: serviceArea.name, amenities: [])
        @unknown default:
            fatalError("Unknown ServiceAreaInfo type.")
        }
    }
}
