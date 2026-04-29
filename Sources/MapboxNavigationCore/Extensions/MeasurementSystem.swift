import Foundation
import MapboxDirections

@available(*, deprecated, message: "Use `UnitMeasurementSystem` instead.")
extension MeasurementSystem {
    /// Converts `LengthFormatter.Unit` into `MapboxDirections.MeasurementSystem`.
    public init(_ lengthUnit: LengthFormatter.Unit) {
        let metricUnits: [LengthFormatter.Unit] = [.kilometer, .centimeter, .meter, .millimeter]
        self = metricUnits.contains(lengthUnit) ? .metric : .imperial
    }
}

extension UnitMeasurementSystem {
    /// Converts `LengthFormatter.Unit` into `MapboxDirections.UnitMeasurementSystem`.
    public init(_ lengthUnit: LengthFormatter.Unit) {
        switch lengthUnit {
        case .kilometer, .centimeter, .meter, .millimeter:
            self = .metric
        case .yard:
            self = .britishImperial
        default:
            self = .imperial
        }
    }
}
