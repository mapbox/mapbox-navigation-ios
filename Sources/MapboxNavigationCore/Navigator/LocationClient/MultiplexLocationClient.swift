import Combine
import CoreLocation
import Foundation

/// Allows switching between sources of location data:
/// ``LocationSource/live`` which sends real GPS locations;
/// ``LocationSource/simulation(initialLocation:)`` that simulates the route traversal;
/// ``LocationSource/custom(_:)`` that allows to provide a custom location data source;
@MainActor
public final class MultiplexLocationClient: @unchecked Sendable {
    private let locations = PassthroughSubject<CLLocation, Never>()
    private let headings = PassthroughSubject<CLHeading, Never>()
    private var currentLocationClient: LocationClient = .empty
    private var isUpdating = false
    private var isUpdatingHeading = false
    private var routeProgress: AnyPublisher<RouteProgressState?, Never> = Just(nil).eraseToAnyPublisher()
    private var rerouteEvents: AnyPublisher<RouteProgress?, Never> = Just(nil).eraseToAnyPublisher()
    private var currentLocationClientSubscriptions: Set<AnyCancellable> = []

    var locationClient: LocationClient {
        .init(
            locations: locations.eraseToAnyPublisher(),
            headings: headings.eraseToAnyPublisher(),
            startUpdatingLocation: { [weak self] in self?.startUpdatingLocation() },
            stopUpdatingLocation: { [weak self] in self?.stopUpdatingLocation() },
            startUpdatingHeading: { [weak self] in self?.startUpdatingHeading() },
            stopUpdatingHeading: { [weak self] in self?.stopUpdatingHeading() }
        )
    }

    var isInitialized: Bool = false

    nonisolated init(source: LocationSource) {
        setLocationSource(source)
    }

    nonisolated func subscribeToNavigatorUpdates(
        _ navigator: MapboxNavigator,
        source: LocationSource
    ) {
        Task { @MainActor in
            self.isInitialized = true
            self.routeProgress = navigator.routeProgress
            self.rerouteEvents = navigator.navigationRoutes
                .map { _ in navigator.currentRouteProgress?.routeProgress }
                .eraseToAnyPublisher()
            setLocationSource(source)
        }
    }

    func startUpdatingLocation() {
        isUpdating = true
        Task { @MainActor in
            currentLocationClient.startUpdatingLocation()
        }
    }

    func stopUpdatingLocation() {
        isUpdating = false
        Task { @MainActor in
            currentLocationClient.stopUpdatingLocation()
        }
    }

    func startUpdatingHeading() {
        isUpdatingHeading = true
        Task { @MainActor in
            currentLocationClient.startUpdatingHeading()
        }
    }

    func stopUpdatingHeading() {
        isUpdatingHeading = false
        Task { @MainActor in
            currentLocationClient.stopUpdatingHeading()
        }
    }

    nonisolated func setLocationSource(_ source: LocationSource) {
        Task { @MainActor in
            let newLocationClient: LocationClient
            switch source {
            case .simulation(let location):
                newLocationClient = .simulatedLocationManager(
                    routeProgress: routeProgress,
                    rerouteEvents: rerouteEvents,
                    initialLocation: location
                )
                if let location {
                    locations.send(location)
                }
            case .live:
                newLocationClient = .liveValue
            case .custom(let customClient):
                newLocationClient = customClient
            }

            currentLocationClient.stopUpdatingHeading()
            currentLocationClient.stopUpdatingLocation()

            if isUpdating {
                newLocationClient.startUpdatingLocation()
            } else {
                newLocationClient.stopUpdatingLocation()
            }

            if isUpdatingHeading {
                newLocationClient.startUpdatingHeading()
            } else {
                newLocationClient.stopUpdatingHeading()
            }

            currentLocationClient = newLocationClient
            currentLocationClientSubscriptions.removeAll()

            newLocationClient.locations
                .subscribe(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.locations.send($0)
                }
                .store(in: &currentLocationClientSubscriptions)
            newLocationClient.headings
                .subscribe(on: DispatchQueue.main)
                .sink { [weak self] in self?.headings.send($0) }
                .store(in: &currentLocationClientSubscriptions)
        }
    }
}

extension LocationClient {
    fileprivate static let empty = LocationClient(
        locations: Empty().eraseToAnyPublisher(),
        headings: Empty().eraseToAnyPublisher(),
        startUpdatingLocation: {},
        stopUpdatingLocation: {},
        startUpdatingHeading: {},
        stopUpdatingHeading: {}
    )
}
