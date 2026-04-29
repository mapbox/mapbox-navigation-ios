import Foundation

extension MainActor {
    /// A safe way to synchronously assume that the current execution context belongs to the MainActor.
    ///
    /// This API should only be used as last resort, when it is not possible to express the current
    /// execution context definitely belongs to the main actor in other ways. E.g. one may need to use
    /// this in a delegate style API, where a synchronous method is guaranteed to be called by the
    /// main actor, however it is not possible to annotate this legacy API with `@MainActor`.
    ///
    /// - Warning: If the current executor is *not* the MainActor's serial executor on iOS >= 17 or current queue isn't
    /// DispatchQueue.main on `iOS < 17`, this function will crash.
    ///
    /// Note that on iOS 17 and higher, this check is performed against the MainActor's serial executor, meaning that
    /// if another actor uses the same serial executor--by using MainActor/sharedUnownedExecutor
    /// as its own Actor/unownedExecutor--this check will succeed, as from a concurrency safety
    /// perspective, the serial executor guarantees mutual exclusion of those two actors.
    ///
    /// - Note: This is a wrapper around stdlib iOS >= 17 only `assumeIsolated` API. Implementation is copied from
    /// https://github.com/apple/swift/blob/498ce63205f1e513711cf5a6c9dfab40111ce5c4/stdlib/public/Concurrency/MainActor.swift#L119
    @_unavailableFromAsync(message: "await the call to the @MainActor closure directly")
    @discardableResult
    public static func assumingIsolated<T>(
        _ operation: @MainActor () throws -> T,
        file: StaticString = #fileID, line: UInt = #line
    ) rethrows -> T {
#if swift(>=5.9)
        if #available(macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0, *) {
            return try Self.assumeIsolated(operation)
        }
#endif

        dispatchPrecondition(condition: .onQueue(.main))
        typealias YesActor = @MainActor () throws -> T
        typealias NoActor = () throws -> T

        // To do the unsafe cast, we have to pretend it's @escaping.
        return try withoutActuallyEscaping(operation) {
            (_ fn: @escaping YesActor) throws -> T in
            let rawFn = unsafeBitCast(fn, to: NoActor.self)
            return try rawFn()
        }
    }
}
