import Foundation

/// If on main thread then performs a work item. If on non-main thread then performs the work item synchronously on main queue.
/// - returns: The return value of the item in the work parameter.
func onMainQueueSync<T>(execute work: () throws -> T) rethrows -> T {
    if Thread.isMainThread {
        return try work()
    }
    else {
        return try DispatchQueue.main.sync {
            try work()
        }
    }
}
