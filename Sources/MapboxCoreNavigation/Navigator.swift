import Foundation
import MapboxNavigationNative

extension MapboxNavigationNative.Navigator {
    
    func status(at timestamp: Date) -> NavigationStatus {
        return try! getStatusForMonotonicTimestampNanoseconds(
            Int64(timestamp.nanosecondsSince1970)
        )
    }
}
