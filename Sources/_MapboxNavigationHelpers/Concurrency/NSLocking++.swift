import Foundation

extension NSLocking {
    /**
     Locks the lock, executes the `block` and unlocks the lock returning the value from the `block`.

     # Example
     ```swift
     let lock = NSLock()
     let counter = 0
     DispatchQueue.concurrentPerform(iterations: 100) { _ in
         lock {
             counter += 1
         }
     }
     ```
     */
    public func callAsFunction<ReturnValue>(_ block: () throws -> ReturnValue) rethrows -> ReturnValue {
        lock(); defer {
            unlock()
        }
        return try block()
    }
}

public typealias NSLocked<Value> = Locked<Value, NSLock>

extension Locked where Lock == NSLock {
    public convenience init(_ wrappedValue: Value) {
        self.init(wrappedValue, lock: NSLock())
    }
}
