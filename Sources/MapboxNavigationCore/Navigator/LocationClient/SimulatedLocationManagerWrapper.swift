import Combine
import CoreLocation

extension LocationClient {
    @MainActor
    static func simulatedLocationManager(
        routeProgress: AnyPublisher<RouteProgressState?, Never>,
        rerouteEvents: AnyPublisher<RouteProgress?, Never>,
        initialLocation: CLLocation?
    ) -> Self {
        let wrapper = SimulatedLocationManagerWrapper(
            routeProgress: routeProgress,
            rerouteEvents: rerouteEvents,
            initialLocation: initialLocation
        )
        return Self(
            locations: wrapper.locations,
            headings: Empty<CLHeading, Never>().eraseToAnyPublisher(),
            startUpdatingLocation: {
                wrapper.startUpdatingLocation()
            },
            stopUpdatingLocation: {
                wrapper.stopUpdatingLocation()
            },
            startUpdatingHeading: {},
            stopUpdatingHeading: {}
        )
    }
}

@MainActor
private class SimulatedLocationManagerWrapper: NavigationLocationManagerDelegate {
    private let manager: SimulatedLocationManager
    private let _locations = PassthroughSubject<CLLocation, Never>()
    private var lifetimeSubscriptions: Set<AnyCancellable> = []

    var locations: AnyPublisher<CLLocation, Never> { _locations.eraseToAnyPublisher() }

    @MainActor
    init(
        routeProgress: AnyPublisher<RouteProgressState?, Never>,
        rerouteEvents: AnyPublisher<RouteProgress?, Never>,
        initialLocation: CLLocation?
    ) {
        self.manager = SimulatedLocationManager(initialLocation: initialLocation)
        manager.locationDelegate = self

        routeProgress.sink { [weak self] in
            self?.manager.progressDidChange($0?.routeProgress)
        }.store(in: &lifetimeSubscriptions)

        rerouteEvents.sink { [weak self] in
            self?.manager.didReroute(progress: $0)
        }.store(in: &lifetimeSubscriptions)
    }

    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }

    nonisolated func navigationLocationManager(
        _ locationManager: NavigationLocationManager,
        didReceiveNewLocation location: CLLocation
    ) {
        Task { @MainActor in
            self._locations.send(location)
        }
    }
}
