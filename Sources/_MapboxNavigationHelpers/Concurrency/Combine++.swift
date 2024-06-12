import Combine

extension AnyCancellable: CancellableAsyncStateValue {}

@available(iOS, deprecated: 15.0, message: "Back ported version isn't needed since iOS 15")
extension Publisher {
    public var values: AsyncThrowingStream<Output, Error> {
        .init { continuation in
            let state: CancellableAsyncState<AnyCancellable> = .init()

            continuation.onTermination = { @Sendable _ in
                state.cancel()
            }

            let cancellable = sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.finish()
                    case .failure(let error):
                        continuation.finish(throwing: error)
                    }
                }, receiveValue: { value in
                    continuation.yield(value)
                }
            )
            state.activate(with: cancellable)
        }
    }
}

@available(iOS, deprecated: 15.0, message: "Back ported version isn't needed since iOS 15")
extension Publisher where Failure == Never {
    public var values: AsyncStream<Output> {
        .init { continuation in
            let state: CancellableAsyncState<AnyCancellable> = .init()

            continuation.onTermination = { @Sendable _ in
                state.cancel()
            }

            let cancellable = sink(
                receiveCompletion: { _ in
                    continuation.finish()
                }, receiveValue: { value in
                    continuation.yield(value)
                }
            )
            state.activate(with: cancellable)
        }
    }
}
