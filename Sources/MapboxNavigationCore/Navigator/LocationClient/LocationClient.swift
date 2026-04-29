import Combine
import CoreLocation

public struct LocationClient: @unchecked Sendable, Equatable {
    var locations: AnyPublisher<CLLocation, Never>
    var headings: AnyPublisher<CLHeading, Never>
    var startUpdatingLocation: @MainActor () -> Void
    var stopUpdatingLocation: @MainActor () -> Void
    var startUpdatingHeading: @MainActor () -> Void
    var stopUpdatingHeading: @MainActor () -> Void

    public init(
        locations: AnyPublisher<CLLocation, Never>,
        headings: AnyPublisher<CLHeading, Never>,
        startUpdatingLocation: @escaping () -> Void,
        stopUpdatingLocation: @escaping () -> Void,
        startUpdatingHeading: @escaping () -> Void,
        stopUpdatingHeading: @escaping () -> Void
    ) {
        self.locations = locations
        self.headings = headings
        self.startUpdatingLocation = startUpdatingLocation
        self.stopUpdatingLocation = stopUpdatingLocation
        self.startUpdatingHeading = startUpdatingHeading
        self.stopUpdatingHeading = stopUpdatingHeading
    }

    private let id = UUID().uuidString
    public static func == (lhs: LocationClient, rhs: LocationClient) -> Bool { lhs.id == rhs.id }
}

extension LocationClient {
    static var liveValue: Self {
        class Delegate: NSObject, CLLocationManagerDelegate {
            var locations: AnyPublisher<CLLocation, Never> {
                locationsSubject.eraseToAnyPublisher()
            }

            var headings: AnyPublisher<CLHeading, Never> {
                headingSubject.eraseToAnyPublisher()
            }

            private let manager = CLLocationManager()
            private let locationsSubject = PassthroughSubject<CLLocation, Never>()
            private let headingSubject = PassthroughSubject<CLHeading, Never>()

            override init() {
                super.init()
                assert(Thread.isMainThread) // CLLocationManager has to be created on the main thread
                manager.requestWhenInUseAuthorization()

                if Bundle.main.backgroundModes.contains("location") {
                    manager.allowsBackgroundLocationUpdates = true
                }
                manager.delegate = self
            }

            func startUpdatingLocation() {
                manager.startUpdatingLocation()
            }

            func stopUpdatingLocation() {
                manager.stopUpdatingLocation()
            }

            func startUpdatingHeading() {
                manager.startUpdatingHeading()
            }

            func stopUpdatingHeading() {
                manager.stopUpdatingHeading()
            }

            nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
                if let location = locations.last {
                    locationsSubject.send(location)
                }
            }

            nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
                headingSubject.send(newHeading)
            }
        }

        let delegate = Delegate()

        return Self(
            locations: delegate.locations,
            headings: delegate.headings,
            startUpdatingLocation: { delegate.startUpdatingLocation() },
            stopUpdatingLocation: { delegate.stopUpdatingLocation() },
            startUpdatingHeading: { delegate.startUpdatingHeading() },
            stopUpdatingHeading: { delegate.stopUpdatingHeading() }
        )
    }
}
