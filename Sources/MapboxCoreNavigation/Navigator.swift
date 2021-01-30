import Foundation
import MapboxNavigationNative

extension Navigator {
    func status(at timestamp: Date) -> NavigationStatus {
        return getStatusForMonotonicTimestampNanoseconds(Int64(timestamp.nanosecondsSince1970))
    }
}
