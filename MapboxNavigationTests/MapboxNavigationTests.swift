import XCTest
import CoreLocation
import CarPlay
@testable import MapboxCoreNavigation
@testable import MapboxNavigation
@testable import MapboxDirections
@_spi(Restricted) @testable import MapboxMaps
import SnapshotTesting

class MapboxNavigationTests: XCTestCase {
    
    var navigationMapView: NavigationMapView!
    
    override func setUpWithError() throws {
        navigationMapView = NavigationMapView(frame: UIScreen.main.bounds)
        
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let rootViewController: UIViewController?
        if #available(iOS 15.0, *) {
            rootViewController = windowScene?.keyWindow?.rootViewController
        } else {
            rootViewController = windowScene?.windows.filter({ $0.isKeyWindow }).first?.rootViewController
        }
        
        guard let rootViewController = rootViewController else {
            XCTFail("Root view controller should be valid.")
            return
        }
        
        rootViewController.view.addSubview(navigationMapView)
    }
    
    override func tearDownWithError() throws {
        navigationMapView.removeFromSuperview()
    }
    
    func testHighlightBuildings() {
        let timeout: TimeInterval = 10.0
        let styleLoadedExpectation = XCTestExpectation(description: "Style loaded expectation.")
        navigationMapView.mapView.mapboxMap.onNext(event: .styleLoaded) { _ in
            styleLoadedExpectation.fulfill()
        }
        wait(for: [styleLoadedExpectation], timeout: timeout)
        
        let cameraOptions = CameraOptions(center: CLLocationCoordinate2D(latitude: 37.79060, longitude: -122.39564),
                                          zoom: 17.0,
                                          bearing: 0.0,
                                          pitch: 0.0)
        navigationMapView.mapView.mapboxMap.setCamera(to: cameraOptions)
        
        let mapLoadedExpectation = XCTestExpectation(description: "Map loaded expectation.")
        navigationMapView.mapView.mapboxMap.onNext(event: .mapLoaded) { _ in
            mapLoadedExpectation.fulfill()
        }
        wait(for: [mapLoadedExpectation], timeout: timeout)
        
        let buildingHighlightCoordinates: [CLLocationCoordinate2D] = [
            CLLocationCoordinate2D(latitude: 37.79066, longitude: -122.39581),
            CLLocationCoordinate2D(latitude: 37.78999, longitude: -122.39485)
        ]
        
        let featureQueryExpectation = XCTestExpectation(description: "Wait for building to be highlighted.")
        navigationMapView.highlightBuildings(at: buildingHighlightCoordinates, in3D: true, completion: { foundAllBuildings in
            if foundAllBuildings {
                featureQueryExpectation.fulfill()
            } else {
                XCTFail("Building highlighted failed.")
            }
        })
        
        wait(for: [featureQueryExpectation], timeout: 2.0)
        
        let buildingExtrusionLayerIdentifier = NavigationMapView.LayerIdentifier.buildingExtrusionLayer
        guard let _ = try? navigationMapView.mapView.mapboxMap.style.layer(withId: buildingExtrusionLayerIdentifier) else {
            XCTFail("Building extrusion layer should be present.")
            return
        }
        
        navigationMapView.unhighlightBuildings()
        
        let buildingExtrusionLayer = try? self.navigationMapView.mapView.mapboxMap.style.layer(withId: buildingExtrusionLayerIdentifier)
        XCTAssertNil(buildingExtrusionLayer, "Building extrusion layer should not be present after removal.")
    }
    
    func testPuck3DLayerPosition() {
        // Change authorization and accuracy to simulate its approval by the user.
        navigationMapView._locationChangesAllowed = false
        navigationMapView.authorizationStatus = .authorizedAlways
        navigationMapView.accuracyAuthorization = .fullAccuracy
        
        let timeout: TimeInterval = 2.0
        let mapLoadedExpectation = XCTestExpectation(description: "Map loaded expectation.")
        navigationMapView.mapView.mapboxMap.onNext(event: .mapLoaded) { _ in
            mapLoadedExpectation.fulfill()
        }
        wait(for: [mapLoadedExpectation], timeout: timeout)
        
        let location = CLLocation(latitude: 37.79066, longitude: -122.39581)
        let simulatedLocationProvider = SimulatedLocationProvider(currentLocation: location)
        navigationMapView.mapView.location.overrideLocationProvider(with: simulatedLocationProvider)
        
        var model = MapboxMaps.Model()
        // Setting asset URL is required for successful 3D puck placement.
        model.uri = URL(string: "http://asset.gltf")!
        let puck3DConfiguration = Puck3DConfiguration(model: model)
        navigationMapView.userLocationStyle = .puck3D(configuration: puck3DConfiguration)
        
        let puckType: PuckType = .puck3D(puck3DConfiguration)
        XCTAssertEqual(navigationMapView.mapView.location.options.puckType, puckType, "Puck type should be set to non-nil value.")
        
        let origin = CLLocationCoordinate2DMake(37.776818, -122.399076)
        let destination = CLLocationCoordinate2DMake(37.777407, -122.399814)
        let navigationRouteOptions = NavigationRouteOptions(coordinates: [origin, destination])
        
        let decoder = JSONDecoder()
        decoder.userInfo[.options] = navigationRouteOptions
        guard let route: Route = try? decoder.decode(Route.self, from: JSONFromFile(name: "route")) else {
            XCTFail("Route should be valid.")
            return
        }
        
        navigationMapView.show([route])
        navigationMapView.addArrow(route: route, legIndex: 0, stepIndex: 0)
        
        // After applying new value to the `NavigationMapView.userLocationStyle`, showing route line and maneuver arrow,
        // wait for some time to load up all layer related changes.
        wait()
        
        let allLayerIdentifiers = navigationMapView.mapView.mapboxMap.style.allLayerIdentifiers.map({ $0.id })
        
        guard let arrowLayerIndex = allLayerIdentifiers.firstIndex(of: NavigationMapView.LayerIdentifier.arrowLayer) else {
            XCTFail("Arrow layer should be valid.")
            return
        }
        
        guard let mainRouteLayerIndex = allLayerIdentifiers.firstIndex(of: route.identifier(.route(isMainRoute: true))) else {
            XCTFail("Main route layer should be valid.")
            return
        }
        
        guard let arrowStrokeLayerIndex = allLayerIdentifiers.firstIndex(of: NavigationMapView.LayerIdentifier.arrowStrokeLayer) else {
            XCTFail("Arrow stroke layer should be valid.")
            return
        }
        
        guard let arrowSymbolLayerIndex = allLayerIdentifiers.firstIndex(of: NavigationMapView.LayerIdentifier.arrowSymbolLayer) else {
            XCTFail("Arrow symbol layer should be valid.")
            return
        }
        
        guard let puck3DLayerIndex = allLayerIdentifiers.firstIndex(of: NavigationMapView.LayerIdentifier.puck3DLayer) else {
            XCTFail("3D puck layer should be valid.")
            return
        }
        
        // It is expected that maneuver arrow stroke layer will be added above main route line layer.
        XCTAssert(mainRouteLayerIndex < arrowStrokeLayerIndex, "Arrow stroke layer should be above main route layer.")
        XCTAssert(arrowLayerIndex < arrowSymbolLayerIndex, "Arrow symbol layer should be below arrow layer.")
        XCTAssert(arrowSymbolLayerIndex < puck3DLayerIndex, "3D puck layer should be below arrow symbol layer.")
    }
    
    func testUserLocationStyle() {
        // Change authorization and accuracy to simulate its approval by the user.
        navigationMapView._locationChangesAllowed = false
        navigationMapView.authorizationStatus = .authorizedAlways
        navigationMapView.accuracyAuthorization = .fullAccuracy
        
        let timeout: TimeInterval = 2.0
        let location = CLLocation(latitude: 37.79060960181454, longitude: -122.39564506250244)
        
        let styleLoadedExpectation = XCTestExpectation(description: "Style loaded expectation.")
        navigationMapView.mapView.mapboxMap.onNext(event: .styleLoaded) { _ in
            styleLoadedExpectation.fulfill()
        }
        wait(for: [styleLoadedExpectation], timeout: timeout)
        
        let cameraOptions = CameraOptions(center: location.coordinate,
                                          zoom: 14.0,
                                          bearing: 0.0,
                                          pitch: 0.0)
        
        navigationMapView.mapView.mapboxMap.setCamera(to: cameraOptions)
        
        let simulatedLocationProvider = SimulatedLocationProvider(currentLocation: location)
        navigationMapView.mapView.location.overrideLocationProvider(with: simulatedLocationProvider)
        
        let mapLoadedExpectation = XCTestExpectation(description: "Map loaded expectation.")
        navigationMapView.mapView.mapboxMap.onNext(event: .mapLoaded) { _ in
            mapLoadedExpectation.fulfill()
        }
        
        navigationMapView.userLocationStyle = nil
        wait()
        assertImageSnapshot(matching: UIImageView(image: navigationMapView.snapshot()), as: .image(precision: 0.95))
        
        navigationMapView.userLocationStyle = .puck2D()
        wait()
        assertImageSnapshot(matching: UIImageView(image: navigationMapView.snapshot()), as: .image(precision: 0.95))
        
        navigationMapView.moveUserLocation(to: location)
        navigationMapView.userLocationStyle = .courseView()
        wait()
        assertImageSnapshot(matching: UIImageView(image: navigationMapView.snapshot()), as: .image(precision: 0.95))
        
        navigationMapView.reducedAccuracyActivatedMode = true
        wait()
        assertImageSnapshot(matching: UIImageView(image: navigationMapView.snapshot()), as: .image(precision: 0.95))
        
        navigationMapView.reducedAccuracyActivatedMode = false
        navigationMapView.authorizationStatus = .denied
        wait()
        assertImageSnapshot(matching: UIImageView(image: navigationMapView.snapshot()), as: .image(precision: 0.95))
        
        navigationMapView.authorizationStatus = .authorizedAlways
        navigationMapView.accuracyAuthorization = .reducedAccuracy
        wait()
        assertImageSnapshot(matching: UIImageView(image: navigationMapView.snapshot()), as: .image(precision: 0.95))
        
        navigationMapView.reducedAccuracyActivatedMode = true
        wait()
        assertImageSnapshot(matching: UIImageView(image: navigationMapView.snapshot()), as: .image(precision: 0.95))
        
        navigationMapView.accuracyAuthorization = .fullAccuracy
        let userPuckCourseView = UserPuckCourseView(frame: .init(origin: .zero, size: .init(width: 50.0, height: 50.0)))
        userPuckCourseView.fillColor = .red
        userPuckCourseView.puckColor = .green
        userPuckCourseView.shadowColor = .blue
        navigationMapView.userLocationStyle = .courseView(userPuckCourseView)
        wait()
        assertImageSnapshot(matching: UIImageView(image: navigationMapView.snapshot()), as: .image(precision: 0.95))
    }
    
    func testRoutePresentationAndRemoval() {
        // Change authorization and accuracy to simulate its approval by the user.
        navigationMapView._locationChangesAllowed = false
        navigationMapView.authorizationStatus = .denied
        navigationMapView.userLocationStyle = nil
        
        let timeout: TimeInterval = 2.0
        let styleLoadedExpectation = XCTestExpectation(description: "Style loaded expectation.")
        navigationMapView.mapView.mapboxMap.onNext(event: .styleLoaded) { _ in
            styleLoadedExpectation.fulfill()
        }
        wait(for: [styleLoadedExpectation], timeout: timeout)
        
        navigationMapView.mapView.mapboxMap.setCamera(to: CameraOptions(zoom: 15.0,
                                                                        bearing: 0.0,
                                                                        pitch: 0.0))
        
        let mapLoadedExpectation = XCTestExpectation(description: "Map loaded expectation.")
        navigationMapView.mapView.mapboxMap.onNext(event: .mapLoaded) { _ in
            mapLoadedExpectation.fulfill()
        }
        
        wait(for: [mapLoadedExpectation], timeout: timeout)
        
        var coordinates = [
            CLLocationCoordinate2DMake(37.766786656393464, -122.41803651931673),
            CLLocationCoordinate2DMake(37.76850632569678, -122.41628613127037)
        ]
        var routeName = "two_routes"
        var routes = self.routes(for: coordinates, routeName: routeName)
        var routeResponse = IndexedRouteResponse(routeResponse: self.routeResponse(for: coordinates, routeName: routeName),
                                                 routeIndex: 0)
        guard let firstRoute = routes.first,
              let centerCoordinate = routes.first?.shape?.coordinates.centerCoordinate else {
            XCTFail("Data should be valid.")
            return
        }
        navigationMapView.mapView.mapboxMap.setCamera(to: CameraOptions(center: centerCoordinate))
        navigationMapView.show(routes)
        navigationMapView.showWaypoints(on: firstRoute)
        wait()
        assertImageSnapshot(matching: UIImageView(image: navigationMapView.snapshot()), as: .image(precision: 0.95))
        
        navigationMapView.removeRoutes()
        navigationMapView.removeWaypoints()
        wait()
        assertImageSnapshot(matching: UIImageView(image: navigationMapView.snapshot()), as: .image(precision: 0.95))
        
        navigationMapView.mapView.mapboxMap.setCamera(to: CameraOptions(center: centerCoordinate))
        navigationMapView.show(routeResponse)
        navigationMapView.showWaypoints(on: firstRoute)
        wait()
        assertImageSnapshot(matching: UIImageView(image: navigationMapView.snapshot()), as: .image(precision: 0.95))
        
        navigationMapView.removeRoutes()
        navigationMapView.removeWaypoints()
        wait()
        assertImageSnapshot(matching: UIImageView(image: navigationMapView.snapshot()), as: .image(precision: 0.95))
        
        coordinates = [
            CLLocationCoordinate2DMake(37.766786656393464, -122.41803651931673),
            CLLocationCoordinate2DMake(37.76850632569678, -122.41628613127037),
            CLLocationCoordinate2DMake(37.768650567520595, -122.41376775457874)
        ]
        routeName = "two_routes_with_two_legs"
        routes = self.routes(for: coordinates, routeName: routeName)
        routeResponse = IndexedRouteResponse(routeResponse: self.routeResponse(for: coordinates, routeName: routeName),
                                                 routeIndex: 0)
        guard let firstRoute = routes.first else {
            XCTFail("Data should be valid.")
            return
        }
        
        navigationMapView.show(routes)
        navigationMapView.showWaypoints(on: firstRoute)
        wait()
        assertImageSnapshot(matching: UIImageView(image: navigationMapView.snapshot()), as: .image(precision: 0.95))
        
        navigationMapView.removeRoutes()
        navigationMapView.removeWaypoints()
        wait()
        assertImageSnapshot(matching: UIImageView(image: navigationMapView.snapshot()), as: .image(precision: 0.95))
        
        navigationMapView.mapView.mapboxMap.setCamera(to: CameraOptions(center: centerCoordinate))
        navigationMapView.show(routeResponse)
        navigationMapView.showWaypoints(on: firstRoute)
        wait()
        assertImageSnapshot(matching: UIImageView(image: navigationMapView.snapshot()), as: .image(precision: 0.95))
        
        navigationMapView.removeRoutes()
        navigationMapView.removeWaypoints()
        wait()
        assertImageSnapshot(matching: UIImageView(image: navigationMapView.snapshot()), as: .image(precision: 0.95))
    }
    
    func testMultiLegRouteWithoutCongestion() {
        navigationMapView._locationChangesAllowed = false
        navigationMapView.authorizationStatus = .denied
        navigationMapView.userLocationStyle = nil
        
        let timeout: TimeInterval = 2.0
        let styleLoadedExpectation = XCTestExpectation(description: "Style loaded expectation.")
        navigationMapView.mapView.mapboxMap.onNext(event: .styleLoaded) { _ in
            styleLoadedExpectation.fulfill()
        }
        wait(for: [styleLoadedExpectation], timeout: timeout)
        
        navigationMapView.mapView.mapboxMap.setCamera(to: CameraOptions(center: CLLocationCoordinate2D(latitude: 37.768506, longitude: -122.416286),
                                                                        zoom: 15.0,
                                                                        bearing: 0.0,
                                                                        pitch: 0.0))
        
        let mapLoadedExpectation = XCTestExpectation(description: "Map loaded expectation.")
        navigationMapView.mapView.mapboxMap.onNext(event: .mapLoaded) { _ in
            mapLoadedExpectation.fulfill()
        }
        wait(for: [mapLoadedExpectation], timeout: timeout)
        
        let coordinates = [
            CLLocationCoordinate2DMake(37.766786656393464, -122.41803651931673),
            CLLocationCoordinate2DMake(37.76850632569678, -122.41628613127037),
            CLLocationCoordinate2DMake(37.768650567520595, -122.41376775457874)
        ]
        let routeName = "two_routes_with_two_legs"
        let routes = routes(for: coordinates, routeName: routeName)
        guard let firstRoute = routes.first else {
            XCTFail("Route should be valid.")
            return
        }

        XCTAssertEqual(firstRoute.legs.count, 2)
        firstRoute.legs.first?.attributes.segmentNumericCongestionLevels = nil
        firstRoute.legs.first?.attributes.segmentCongestionLevels = nil
        firstRoute.legs.last?.attributes.segmentNumericCongestionLevels = nil
        firstRoute.legs.last?.attributes.segmentCongestionLevels = nil
        
        XCTAssertNil(firstRoute.legs.first?.resolvedCongestionLevels)
        XCTAssertNil(firstRoute.legs.last?.resolvedCongestionLevels)
        
        navigationMapView.show([firstRoute], legIndex: 0)
        navigationMapView.showWaypoints(on: firstRoute)
        wait()
        assertImageSnapshot(matching: UIImageView(image: navigationMapView.snapshot()), as: .image(precision: 0.95))
    }
    
    func routeResponse(for coordinates: [CLLocationCoordinate2D], routeName: String) -> RouteResponse {
        let navigationRouteOptions = NavigationRouteOptions(coordinates: coordinates)
        
        let decoder = JSONDecoder()
        decoder.userInfo[.options] = navigationRouteOptions
        
        let data = JSONFromFile(name: routeName)
        
        let routes = try? decoder.decode([Route].self, from: data)
        return RouteResponse(httpResponse: nil,
                             routes: routes,
                             waypoints: navigationRouteOptions.waypoints,
                             options: .route(navigationRouteOptions),
                             credentials: Credentials())
    }
    
    func routes(for coordinates: [CLLocationCoordinate2D], routeName: String) -> [Route] {
        let navigationRouteOptions = NavigationRouteOptions(coordinates: coordinates)
        
        let decoder = JSONDecoder()
        decoder.userInfo[.options] = navigationRouteOptions
        
        let data = JSONFromFile(name: routeName)
        
        do {
            let routes = try decoder.decode([Route].self, from: data)
            return routes
        } catch {
            XCTFail("Error occured while decoding routes: \(error.localizedDescription).")
        }
        
        return []
    }
    
    func wait(timeout: TimeInterval = 1.0) {
        let waitExpectation = expectation(description: "Wait expectation.")
        _ = XCTWaiter.wait(for: [waitExpectation], timeout: timeout)
    }
    
    func JSONFromFile(name: String) -> Data {
        guard let path = Bundle.main.path(forResource: name, ofType: "json") else {
            preconditionFailure("File \(name) not found.")
        }
        
        guard let data = NSData(contentsOfFile: path) as Data? else {
            preconditionFailure("No data found at \(path).")
        }
        
        return data
    }
    
    func assertImageSnapshot<Value, Format>(matching value: @autoclosure () throws -> Value,
                                            as snapshotting: Snapshotting<Value, Format>,
                                            named name: String? = nil,
                                            record recording: Bool = false,
                                            timeout: TimeInterval = 5,
                                            file: StaticString = #file,
                                            testName: String = #function,
                                            line: UInt = #line) {
        let fileUrl = URL(fileURLWithPath: "\(file)", isDirectory: false)
        let snapshotDeviceName: String = ProcessInfo.processInfo
            .environment["SIMULATOR_MODEL_IDENTIFIER"]!
            .replacingOccurrences(of: ",", with: "_")
        let operatingSystemVersion: String = UIDevice.current.systemVersion
        let fileName = fileUrl.deletingPathExtension().lastPathComponent
        
        let snapshotDirectoryUrl = fileUrl
            .deletingLastPathComponent()
            .appendingPathComponent("__Snapshots__")
            .appendingPathComponent(snapshotDeviceName)
            .appendingPathComponent(operatingSystemVersion)
            .appendingPathComponent(fileName)
        
        guard let message = verifySnapshot(matching: try value(),
                                           as: snapshotting,
                                           named: name,
                                           record: recording,
                                           snapshotDirectory: snapshotDirectoryUrl.path,
                                           timeout: timeout,
                                           file: file,
                                           testName: testName,
                                           line: line) else {
            return
        }
        
        XCTFail(message, file: file, line: line)
    }
}
