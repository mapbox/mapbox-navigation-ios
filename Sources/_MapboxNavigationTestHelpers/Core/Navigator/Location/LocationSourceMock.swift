import Combine
import CoreLocation
import MapboxNavigationCore

extension LocationClient {
    public static func mockLocationClient(
        locationPublisher: AnyPublisher<CLLocation, Never>
    ) -> LocationClient {
        var updatingLocation = true
        return Self(
            locations: locationPublisher
                .filter { _ in updatingLocation }
                .eraseToAnyPublisher(),
            headings: Empty<CLHeading, Never>().eraseToAnyPublisher(),
            startUpdatingLocation: {
                updatingLocation = true
            },
            stopUpdatingLocation: {
                updatingLocation = false
            },
            startUpdatingHeading: {},
            stopUpdatingHeading: {}
        )
    }
}
