import Combine
import CoreLocation
import MapboxDirections
import MapboxMaps
import Turf
import UIKit

@MainActor
class CommonViewportDataSource {
    var navigationCameraOptions: AnyPublisher<NavigationCameraOptions, Never> {
        _navigationCameraOptions.eraseToAnyPublisher()
    }

    private var _navigationCameraOptions: CurrentValueSubject<NavigationCameraOptions, Never> = .init(.init())

    var currentNavigationCameraOptions: NavigationCameraOptions {
        get {
            _navigationCameraOptions.value
        }

        set {
            _navigationCameraOptions.value = newValue
        }
    }

    var options: NavigationViewportDataSourceOptions = .init()

    weak var mapView: MapView?

    private let viewportParametersProvider: ViewportParametersProvider
    private var updateTask: Task<Void, Never>?

    private var previousViewportParameters: ViewportDataSourceState?
    private var workQueue: DispatchQueue = .init(
        label: "com.mapbox.navigation.camera",
        qos: .userInteractive,
        autoreleaseFrequency: .workItem
    )

    // MARK: Initializer Methods

    required init(_ mapView: MapView) {
        self.mapView = mapView
        self.viewportParametersProvider = .init()
    }

    func update(
        using viewportState: ViewportState,
        updateClosure: @escaping (ViewportDataSourceState) -> NavigationCameraOptions?
    ) {
        updateTask?.cancel()
        updateTask = Task { [weak self] in
            await self?.performUpdate(using: viewportState, updateClosure: updateClosure)
        }
    }

    @MainActor
    func performUpdate(
        using viewportState: ViewportState,
        updateClosure: @escaping (ViewportDataSourceState) -> NavigationCameraOptions?
    ) async {
        guard !Task.isCancelled else { return }

        let viewportParameters = await viewportParameters(with: viewportState)
        guard viewportParameters != previousViewportParameters else { return }

        previousViewportParameters = viewportParameters
        if let newOptions = updateClosure(viewportParameters) {
            _navigationCameraOptions.send(newOptions)
        }
    }

    private func viewportParameters(with viewportState: ViewportState) async -> ViewportDataSourceState {
        await withCheckedContinuation { continuation in
            let options = options
            let provider = viewportParametersProvider
            workQueue.async {
                let parameters = provider.parameters(
                    with: viewportState.location,
                    navigationHeading: viewportState.navigationHeading,
                    routeProgress: viewportState.routeProgress,
                    viewportPadding: viewportState.viewportPadding,
                    options: options
                )
                continuation.resume(returning: parameters)
            }
        }
    }
}
