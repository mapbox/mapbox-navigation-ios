import Foundation

public final class UnfairLock: NSLocking, Sendable {
    private let unfairLock: UnsafeMutablePointer<os_unfair_lock> = {
        let pointer = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        pointer.initialize(to: os_unfair_lock())
        return pointer
    }()

    public init() {}

    deinit {
        unfairLock.deinitialize(count: 1)
        unfairLock.deallocate()
    }

    public func lock() {
        os_unfair_lock_lock(unfairLock)
    }

    public func unlock() {
        os_unfair_lock_unlock(unfairLock)
    }
}

extension UnsafeMutablePointer<os_unfair_lock>: @unchecked Sendable {}

public typealias UnfairLocked<Value> = Locked<Value, UnfairLock>

extension Locked where Lock == UnfairLock {
    public convenience init(_ wrappedValue: Value) {
        self.init(wrappedValue, lock: UnfairLock())
    }
}
