import Foundation
import MapboxNavigationNative

extension Navigator {
    func status(at timestamp: Date) -> NavigationStatus {
        // Because `FixLocation(_:)` passes in a nonzero `monotonicTimestampNanoseconds`, we need to always call `getStatusForMonotonicTimestampNanoseconds(_:)` instead of `getStatusForTimestamp(_:)`.
        // In practice, “submillisecond precision” is 10 nanosecond precision at best, but convert the timestamp to nanoseconds anyways.
        // Unlike on Android, we aren’t concerned about the timestamps’ monotonicity.
        return getStatusForMonotonicTimestampNanoseconds(UInt64(timestamp.nanosecondsSince1970))
    }
}
