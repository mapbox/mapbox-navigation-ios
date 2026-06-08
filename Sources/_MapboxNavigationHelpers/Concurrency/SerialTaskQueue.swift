import Foundation

/// Executes enqueued async tasks one at a time, each waiting for the previous to finish.
public actor SerialTaskQueue {
    private var currentTask: Task<Void, Never>?

    public init() {}

    public func enqueue(_ body: @escaping @Sendable () async -> Void) {
        let previous = currentTask
        currentTask = Task {
            await previous?.value
            await body()
        }
    }
}
