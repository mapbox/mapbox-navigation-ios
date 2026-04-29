import Foundation

/// A cancellation token which is used in ``CancellableAsyncState``
public protocol CancellableAsyncStateValue {
    func cancel()
}

/// Maintains cancellation state which is used when implementing legacy concurrency approach to async/await.
public final class CancellableAsyncState<Task: CancellableAsyncStateValue>: @unchecked Sendable {
    private let lock: UnfairLock = .init()
    private var task: Task?
    private var isCancelled: Bool = false

    public init() {}

    public func activate(with task: Task) {
        lock.lock()
        if self.task != nil {
            assertionFailure("Cannot active CancellableAsyncState twice")
            return
        }
        if isCancelled {
            lock.unlock()
            task.cancel()
        } else {
            isCancelled = false
            self.task = task
            lock.unlock()
        }
    }

    public func cancel() {
        lock.lock()
        let task = task
        isCancelled = true
        self.task = nil
        lock.unlock()

        task?.cancel()
    }
}
