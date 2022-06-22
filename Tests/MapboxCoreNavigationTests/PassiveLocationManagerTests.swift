import Foundation
import MapboxNavigationNative
import TestHelper
import XCTest
@testable import MapboxCoreNavigation

class Road {
    let from: CLLocationCoordinate2D
    let to: CLLocationCoordinate2D
    let length: Double

    init(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        self.from = from
        self.to = to
        self.length = (to - from).length()
    }

    func whichCloser(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        return proximity(of: a) > proximity(of: b) ? b : a
    }

    func proximity(of: CLLocationCoordinate2D) -> Double {
        return ((of - from).length() + (of - to).length()) / length
    }
}

extension CLLocationCoordinate2D {
    static func -(a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: a.latitude - b.latitude, longitude: a.longitude - b.longitude)
    }

    func length() -> Double {
        return sqrt(latitude * latitude + longitude * longitude)
    }
}

class PassiveLocationManagerTests: TestCase {
    class Delegate: PassiveLocationManagerDelegate {
        let road: Road
        let locationUpdateExpectation: XCTestExpectation
        
        init(road: Road, locationUpdateExpectation: XCTestExpectation) {
            self.road = road
            self.locationUpdateExpectation = locationUpdateExpectation
        }
        
        func passiveLocationManagerDidChangeAuthorization(_ manager: PassiveLocationManager) {
        }
        
        func passiveLocationManager(_ manager: PassiveLocationManager, didUpdateLocation location: CLLocation, rawLocation: CLLocation) {
            print("Got location: \(rawLocation.coordinate.latitude), \(rawLocation.coordinate.longitude) → \(location.coordinate.latitude), \(location.coordinate.longitude)")
            print("Value: \(road.proximity(of: location.coordinate)) should be less or equal to \(road.proximity(of: rawLocation.coordinate))")

            XCTAssert(road.proximity(of: location.coordinate) <= road.proximity(of: rawLocation.coordinate), "Raw Location wasn't mapped to a road")
        }
        
        func passiveLocationManager(_ manager: PassiveLocationManager, didUpdateHeading newHeading: CLHeading) {
        }
        
        func passiveLocationManager(_ manager: PassiveLocationManager, didFailWithError error: Error) {
        }
    }
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let bundle = Bundle(for: Fixture.self)
        let filePathURL: URL = URL(fileURLWithPath: bundle.bundlePath.appending("/tiles/liechtenstein"))
        NavigationSettings.shared.initialize(directions: .mocked, tileStoreConfiguration: TileStoreConfiguration(navigatorLocation: .custom(filePathURL), mapLocation: nil), routingProviderSource: .offline, alternativeRouteDetectionStrategy: .init())
    }
    
    override func tearDown() {
        super.tearDown()
        PassiveLocationManager.historyDirectoryURL = nil
        NavigationSettings.shared.initialize(directions: .mocked, tileStoreConfiguration: TileStoreConfiguration(navigatorLocation: .default, mapLocation: nil), routingProviderSource: .hybrid, alternativeRouteDetectionStrategy: .init())
        HistoryRecorder._recreateHistoryRecorder()
    }
    
    func testManualLocations() {
        let locationUpdateExpectation = expectation(description: "Location manager takes some time to start mapping locations to a road graph")
        locationUpdateExpectation.expectedFulfillmentCount = 1
        
        let road = Road(from: CLLocationCoordinate2D(latitude: 47.207966, longitude: 9.527012), to: CLLocationCoordinate2D(latitude: 47.209518, longitude: 9.522167))
        let delegate = Delegate(road: road, locationUpdateExpectation: locationUpdateExpectation)
        let date = Date()
        let locationManager = PassiveLocationManager()
        locationManager.updateLocation(CLLocation(latitude: 47.208674, longitude: 9.524650, timestamp: date.addingTimeInterval(-5)))
        locationManager.delegate = delegate
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(500)) {
            Navigator.shared.navigator.reset {
                locationManager.updateLocation(CLLocation(latitude: 47.208943, longitude: 9.524707, timestamp: date.addingTimeInterval(-4)))
                locationManager.updateLocation(CLLocation(latitude: 47.209082, longitude: 9.524319, timestamp: date.addingTimeInterval(-3)))
                locationManager.updateLocation(CLLocation(latitude: 47.209229, longitude: 9.523838, timestamp: date.addingTimeInterval(-2)))
                locationManager.updateLocation(CLLocation(latitude: 47.209612, longitude: 9.522629, timestamp: date.addingTimeInterval(-1)))
                locationManager.updateLocation(CLLocation(latitude: 47.209842, longitude: 9.522377, timestamp: date.addingTimeInterval(0)))

                locationUpdateExpectation.fulfill()
            }
        }
        wait(for: [locationUpdateExpectation], timeout: 5)
    }
    
    func testNoHistoryRecording() {
        PassiveLocationManager.historyDirectoryURL = nil
        PassiveLocationManager.startRecordingHistory()
                
        let historyCallbackExpectation = XCTestExpectation(description: "History callback should be called")
        PassiveLocationManager.stopRecordingHistory { url in
            XCTAssertNil(url)
            historyCallbackExpectation.fulfill()
        }
        wait(for: [historyCallbackExpectation], timeout: 3)
    }
    
    func testHistoryRecording() {
        let supportDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!.appendingPathComponent("test")
        
        PassiveLocationManager.historyDirectoryURL = supportDir
        withExtendedLifetime(HistoryRecorder.shared) { _ in
            PassiveLocationManager.startRecordingHistory()

            let historyCallbackExpectation = XCTestExpectation(description: "History callback should be called")
            PassiveLocationManager.stopRecordingHistory { url in
                XCTAssertNotNil(url)
                historyCallbackExpectation.fulfill()
            }
            wait(for: [historyCallbackExpectation], timeout: 3)
        }
    }
}

private extension CLLocation {
    convenience init(latitude: CLLocationDegrees, longitude: CLLocationDegrees, timestamp: Date) {
        self.init(
            coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            altitude: 0,
            horizontalAccuracy: 0,
            verticalAccuracy: 0,
            timestamp: timestamp
        )
    }
}
