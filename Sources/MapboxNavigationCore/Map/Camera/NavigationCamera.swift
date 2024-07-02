import _MapboxNavigationHelpers
import Combine
import CoreLocation
import Foundation
import MapboxDirections
import MapboxMaps
import UIKit

/// ``NavigationCamera`` class provides functionality, which allows to manage camera-related states and transitions in a
/// typical navigation scenarios. It's fed with `CameraOptions` via the ``ViewportDataSource`` protocol and executes
/// transitions using ``CameraStateTransition`` protocol.

@MainActor
public class NavigationCamera {
    struct State: Equatable {
        var cameraState: NavigationCameraState = .idle
        var location: CLLocation?
        var heading: CLHeading?
        var routeProgress: RouteProgress?
        var viewportPadding: UIEdgeInsets = .zero
    }

    /// Notifies that the navigation camera state has changed.
    public var cameraStates: AnyPublisher<NavigationCameraState, Never> {
        _cameraStates.eraseToAnyPublisher()
    }

    private let _cameraStates: PassthroughSubject<NavigationCameraState, Never> = .init()

    /// The padding applied to the viewport.
    public var viewportPadding: UIEdgeInsets {
        set {
            state.viewportPadding = newValue
        }
        get {
            state.viewportPadding
        }
    }

    private let _states: PassthroughSubject<State, Never> = .init()

    private var state: State = .init() {
        didSet {
            _states.send(state)
        }
    }

    private var lifetimeSubscriptions: Set<AnyCancellable> = []
    private var isTransitioningCameraState: Bool = false
    private var lastCameraState: NavigationCameraState = .idle

    /// Initializes ``NavigationCamera`` instance.
    ///  - Parameters:
    ///   - mapView: An instance of `MapView`, on which camera-related transitions will be executed.
    ///   - location: A publisher that emits current user location.
    ///   - routeProgress: A publisher that emits route navigation progress.
    ///   - heading: A publisher that emits current user heading. Defaults to `nil.`
    ///   - navigationCameraType: Type of ``NavigationCamera``, which is used for the current instance of
    /// ``NavigationMapView``.
    ///   - viewportDataSource: An object is used to provide location-related data to perform camera-related updates
    /// continuously.
    ///   - cameraStateTransition: An object, which is used to execute camera transitions. By default
    /// ``NavigationCamera`` uses ``NavigationCameraStateTransition``.
    public required init(
        _ mapView: MapView,
        location: AnyPublisher<CLLocation, Never>,
        routeProgress: AnyPublisher<RouteProgress?, Never>,
        heading: AnyPublisher<CLHeading, Never>? = nil,
        navigationCameraType: NavigationCameraType = .mobile,
        viewportDataSource: ViewportDataSource? = nil,
        cameraStateTransition: CameraStateTransition? = nil
    ) {
        self.viewportDataSource = viewportDataSource ?? {
            switch navigationCameraType {
            case .mobile:
                return MobileViewportDataSource(mapView)
            case .carPlay:
                return CarPlayViewportDataSource(mapView)
            }
        }()
        self.cameraStateTransition = cameraStateTransition ?? NavigationCameraStateTransition(mapView)
        observe(location: location)
        observe(routeProgress: routeProgress)
        observe(heading: heading)
        observe(viewportDataSource: self.viewportDataSource)

        _states
            .debounce(for: 0.2, scheduler: DispatchQueue.main)
            .sink { [weak self] newState in
                guard let self else { return }
                if let location = newState.location {
                    self.viewportDataSource.update(
                        using: ViewportState(
                            location: location,
                            routeProgress: newState.routeProgress,
                            viewportPadding: viewportPadding,
                            heading: newState.heading
                        )
                    )
                }
                if newState.cameraState != lastCameraState {
                    update(using: newState.cameraState)
                }
            }.store(in: &lifetimeSubscriptions)

        // Uncomment to be able to see `NavigationCameraDebugView`.
//         setupDebugView(mapView)
    }

    /// Updates the current camera state.
    /// - Parameter cameraState: A new camera state.
    public func update(cameraState: NavigationCameraState) {
        guard cameraState != state.cameraState else { return }
        state.cameraState = cameraState
        _cameraStates.send(cameraState)
    }

    /// Call to this method immediately moves ``NavigationCamera`` to ``NavigationCameraState/idle`` state and stops all
    /// pending transitions.
    public func stop() {
        update(cameraState: .idle)
        cameraStateTransition.cancelPendingTransition()
    }

    private var debugView: NavigationCameraDebugView?

    private func setupDebugView(_ mapView: MapView) {
        let debugView = NavigationCameraDebugView(mapView, viewportDataSource: viewportDataSource)
        self.debugView = debugView
        mapView.addSubview(debugView)
    }

    private func observe(location: AnyPublisher<CLLocation, Never>) {
        location.sink { [weak self] in
            self?.state.location = $0
        }.store(in: &lifetimeSubscriptions)
    }

    private func observe(routeProgress: AnyPublisher<RouteProgress?, Never>) {
        routeProgress.sink { [weak self] in
            self?.state.routeProgress = $0
        }.store(in: &lifetimeSubscriptions)
    }

    private func observe(heading: AnyPublisher<CLHeading, Never>?) {
        guard let heading else { return }
        heading.sink { [weak self] in
            self?.state.heading = $0
        }.store(in: &lifetimeSubscriptions)
    }

    private var viewportSubscription: [AnyCancellable] = []

    private func observe(viewportDataSource: ViewportDataSource) {
        viewportSubscription = []

        viewportDataSource.navigationCameraOptions
            .removeDuplicates()
            .sink { [weak self] navigationCameraOptions in
                guard let self else { return }
                update(using: navigationCameraOptions)
            }.store(in: &viewportSubscription)

        // To prevent the lengthy animation from the Null Island to the current location use the camera to transition to
        // the following state.
        // The following camera options zoom should be calculated before at the moment.
        viewportDataSource.navigationCameraOptions
            .filter { $0.followingCamera.zoom != nil }
            .first()
            .sink { [weak self] _ in
                self?.update(cameraState: .following)
            }.store(in: &viewportSubscription)
    }

    private func update(using cameraState: NavigationCameraState) {
        lastCameraState = cameraState

        switch cameraState {
        case .idle:
            break
        case .following:
            switchToViewportDatasourceCamera(isFollowing: true)
        case .overview:
            switchToViewportDatasourceCamera(isFollowing: false)
        }
    }

    private func cameraOptionsForCurrentState(from navigationCameraOptions: NavigationCameraOptions) -> CameraOptions? {
        switch state.cameraState {
        case .following:
            return navigationCameraOptions.followingCamera
        case .overview:
            return navigationCameraOptions.overviewCamera
        case .idle:
            return nil
        }
    }

    private func update(using navigationCameraOptions: NavigationCameraOptions) {
        guard !isTransitioningCameraState,
              let options = cameraOptionsForCurrentState(from: navigationCameraOptions) else { return }

        cameraStateTransition.update(to: options, state: state.cameraState)
    }

    // MARK: Changing NavigationCamera State

    /// A type, which is used to provide location related data to continuously perform camera-related updates.
    /// By default ``NavigationMapView`` uses ``MobileViewportDataSource`` or ``CarPlayViewportDataSource`` depending on
    /// the current ``NavigationCameraType``.
    public var viewportDataSource: ViewportDataSource {
        didSet {
            observe(viewportDataSource: viewportDataSource)
        }
    }

    /// The current state of ``NavigationCamera``. Defaults to ``NavigationCameraState/idle``.
    ///
    /// Call ``update(cameraState:)`` to update this value.
    public var currentCameraState: NavigationCameraState {
        state.cameraState
    }

    /// A type, which is used to execute camera transitions.
    /// By default ``NavigationMapView`` uses ``NavigationCameraStateTransition``.
    public var cameraStateTransition: CameraStateTransition

    private func switchToViewportDatasourceCamera(isFollowing: Bool) {
        let cameraOptions: CameraOptions = {
            if isFollowing {
                return viewportDataSource.currentNavigationCameraOptions.followingCamera
            } else {
                return viewportDataSource.currentNavigationCameraOptions.overviewCamera
            }
        }()
        isTransitioningCameraState = true
        cameraStateTransition.transitionTo(cameraOptions) { [weak self] in
            self?.isTransitioningCameraState = false
        }
    }
}

extension CameraOptions: @unchecked Sendable {}
