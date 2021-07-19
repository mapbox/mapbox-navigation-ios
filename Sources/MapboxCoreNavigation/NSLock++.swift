import Foundation

@_spi(MapboxInternal)
extension NSLock {
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
