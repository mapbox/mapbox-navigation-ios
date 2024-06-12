import Foundation

/// Wraps `Value` under `Lock`.
/// - Important: This type contains unsafe methods which you must use only when `Locked.init(_:lock:)` init is used and
///              the provided lock is locked. This is useful when you have a lot of atomic variables which you want to
///              modify protected by one lock.
public final class Locked<Value, Lock: NSLocking>: @unchecked Sendable {
    private let lock: Lock
    private var value: Value

    /// Creates a new locked value with initial value and protect with a given lock.
    /// - Parameters:
    ///   - wrappedValue: Initial value.
    ///   - lock: The lock that will be used to protect access to the wrappedValue.
    public init(_ wrappedValue: Value, lock: Lock) {
        self.value = wrappedValue
        self.lock = lock
    }

    /// Safely reads the protected value.
    public func read() -> Value {
        lock.withLock { value }
    }

    /// Safely reads the protected value with the `protectedBlock` block.
    ///
    /// - Important: The lock is locked while `protectedBlock` is executing.
    /// - Returns: A value returned from `protectedBlock`.
    public func read<Output>(_ protectedBlock: (Value) throws -> Output) rethrows -> Output {
        try lock.withLock {
            try protectedBlock(value)
        }
    }

    /// Safely reads a key path references by `keyPath` from protected value.
    public func read<Output>(_ keyPath: KeyPath<Value, Output>) -> Output {
        lock.withLock { value[keyPath: keyPath] }
    }

    /// Safely updates the protected value.
    public func update(_ newValue: Value) {
        lock.withLock { value = newValue }
    }

    /// Safely mutates the protected value with the `mutation` block.
    ///
    /// - Returns: A value returned from the `mutation` block.
    public func mutate<Output>(_ mutation: (inout Value) throws -> Output) rethrows -> Output {
        try withLock(mutation)
    }

    private func withLock<Output>(_ block: (inout Value) throws -> Output) rethrows -> Output {
        lock.lock()
        defer {
            lock.unlock()
        }
        return try block(&value)
    }
}
