import Foundation

/**
 If on main thread then perform `work` block immediately, otherwise asynchrounsly perform `work` block on the main queue.
 */
public func onMainAsync(_ work: @Sendable @MainActor @escaping () -> Void) {
    if Thread.isMainThread {
        MainActor.assumingIsolated {
            work()
        }
    } else {
        DispatchQueue.main.async(execute: work)
    }
}

/**
 If on main thread then performs a work item.
 If on non-main thread then performs the work item synchronously on main queue.

 - returns: The return value of the item in the work parameter.
 */
public func onMainQueueSync<T>(execute work: @MainActor () throws -> T) rethrows -> T {
    if Thread.isMainThread {
        return try MainActor.assumingIsolated {
            return try work()
        }
    } else {
        return try DispatchQueue.main.sync {
            try MainActor.assumingIsolated {
                try work()
            }
        }
    }
}
