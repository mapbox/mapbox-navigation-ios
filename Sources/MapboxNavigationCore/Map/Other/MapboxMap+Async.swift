import _MapboxNavigationHelpers
import MapboxMaps

extension MapboxMap {
    @MainActor
    func queryRenderedFeatures(
        with point: CGPoint,
        options: RenderedQueryOptions? = nil
    ) async throws -> [QueriedRenderedFeature] {
        let state: CancellableAsyncState<AnyMapboxMapsCancelable> = .init()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let cancellable = queryRenderedFeatures(with: point, options: options) { result in
                    continuation.resume(with: result)
                }
                state.activate(with: .init(cancellable))
            }
        } onCancel: {
            state.cancel()
        }
    }

    @MainActor
    func queryRenderedFeatures(
        with rect: CGRect,
        options: RenderedQueryOptions? = nil
    ) async throws -> [QueriedRenderedFeature] {
        let state: CancellableAsyncState<AnyMapboxMapsCancelable> = .init()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let cancellable = queryRenderedFeatures(with: rect, options: options) { result in
                    continuation.resume(with: result)
                }
                state.activate(with: .init(cancellable))
            }
        } onCancel: {
            state.cancel()
        }
    }
}

private final class AnyMapboxMapsCancelable: CancellableAsyncStateValue {
    private let mapboxMapsCancellable: any MapboxMaps.Cancelable

    init(_ mapboxMapsCancellable: any MapboxMaps.Cancelable) {
        self.mapboxMapsCancellable = mapboxMapsCancellable
    }

    func cancel() {
        mapboxMapsCancellable.cancel()
    }
}
