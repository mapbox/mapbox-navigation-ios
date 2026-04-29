import Foundation
import MapboxDirections
import MapboxNavigationCore

extension Locale {
    var unitMeasurementSystem: UnitMeasurementSystem {
        return .init(locale: self)
    }
}
