
import Foundation
import MapboxNavigationNative
import MapboxDirections

extension RestStop {
    init(_ serviceArea: ServiceAreaInfo) {
        switch serviceArea.type {
        case .restArea:
            self.init(type: .restArea)
        case .serviceArea:
            self.init(type: .serviceArea)
        @unknown default:
            fatalError("Unknown ServiceAreaInfo type.")
        }
    }
}
