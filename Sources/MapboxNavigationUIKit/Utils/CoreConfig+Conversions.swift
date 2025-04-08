import MapboxDirections
import MapboxNavigationCore

extension CoreConfig {
    var distanceMeasurementSystem: MeasurementSystem {
        switch unitOfMeasurement {
        case .auto:
            locale.usesMetricSystem ? .metric : .imperial
        case .metric:
            .metric
        case .imperial:
            .imperial
        }
    }
}
