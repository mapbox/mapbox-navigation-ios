import Foundation
import MapboxNavigationNative

extension MapboxNavigationNative.Navigator {
    
    func status(at timestamp: Date) -> NavigationStatus {
        guard let status = try? getStatusForMonotonicTimestampNanoseconds(Int64(timestamp.nanosecondsSince1970)) else {
            fatalError()
        }
        return status
    }
}
