import Foundation

/// Protects access to `Value` by using GCD Queue.
public final class QueueGuard<Value>: @unchecked Sendable {
    private let queue: DispatchQueue
    private var value: Value

    public init(
        _ initialValue: Value,
        queueLabel: String,
        target: DispatchQueue? = nil
    ) {
        self.value = initialValue
        self.queue = .init(label: queueLabel, target: target)
    }

    public func async<Output>(
        _ exclusiveAccessBlock: @Sendable @escaping (inout Value) -> Output
    ) async -> Output {
        await withUnsafeContinuation { continuation in
            queue.async {
                let output = exclusiveAccessBlock(&self.value)
                continuation.resume(returning: output)
            }
        }
    }

    public func async<Output>(
        _ exclusiveAccessBlock: @Sendable @escaping (inout Value) throws -> Output
    ) async throws -> Output {
        try await withUnsafeThrowingContinuation { continuation in
            queue.async {
                do {
                    let output = try exclusiveAccessBlock(&self.value)
                    continuation.resume(returning: output)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    public func sync<Output>(
        _ exclusiveAccessBlock: @Sendable (inout Value) throws -> Output
    ) rethrows -> Output {
        try queue.sync {
            try exclusiveAccessBlock(&self.value)
        }
    }
}
