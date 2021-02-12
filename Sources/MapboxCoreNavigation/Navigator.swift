import Foundation
import MapboxNavigationNative

extension Navigator {
    func status(at timestamp: Date) -> NavigationStatus {
        return try! getStatusForMonotonicTimestampNanoseconds(Int64(timestamp.nanosecondsSince1970))
    }
}
