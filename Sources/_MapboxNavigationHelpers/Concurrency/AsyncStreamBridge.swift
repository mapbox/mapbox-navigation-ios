/// An async sequance (`AsyncSequance`) with an API to produce elements from synchrous context.
public final class AsyncStreamBridge<Element> {
    private let underlyingStream: AsyncStream<Element>
    private let continuation: AsyncStream<Element>.Continuation!

    public init(bufferingPolicy: AsyncStream<Element>.Continuation.BufferingPolicy = .unbounded) {
        var continuation: AsyncStream<Element>.Continuation!
        let underlyingStream = AsyncStream<Element>(bufferingPolicy: bufferingPolicy) {
            // This block is called synchronously.
            continuation = $0
        }
        self.continuation = continuation
        self.underlyingStream = underlyingStream
    }

    deinit {
        continuation.finish()
    }

    public func yield(_ value: Element) {
        continuation.yield(value)
    }

    public func finish() {
        continuation.finish()
    }
}

extension AsyncStreamBridge: AsyncSequence {
    public func makeAsyncIterator() -> AsyncStream<Element>.AsyncIterator {
        underlyingStream.makeAsyncIterator()
    }
}

extension AsyncStreamBridge: Sendable where Element: Sendable {}

extension AsyncStreamBridge where Element == Void {
    public func yield() {
        yield(())
    }
}
