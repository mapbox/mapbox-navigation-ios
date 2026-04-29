import Combine
import CoreLocation
import MapboxNavigationCore

extension LocationClient {
    public static func mockLocationClient(
        locationPublisher: AnyPublisher<CLLocation, Never>,
        state: MockLocationClientState = MockLocationClientState()
    ) -> LocationClient {
        LocationClient(
            locations: locationPublisher.eraseToAnyPublisher(),
            headings: Empty<CLHeading, Never>().eraseToAnyPublisher(),
            startUpdatingLocation: {
                state.updatingLocation = true
            },
            stopUpdatingLocation: {
                state.updatingLocation = false
            },
            startUpdatingHeading: {
                state.updatingHeading = true
            },
            stopUpdatingHeading: {
                state.updatingHeading = false
            }
        )
    }
}

public final class MockLocationClientState {
    public var updatingLocation = false
    public var updatingHeading = false

    public init(
        updatingLocation: Bool = false,
        updatingHeading: Bool = false
    ) {
        self.updatingLocation = updatingLocation
        self.updatingHeading = updatingHeading
    }
}
