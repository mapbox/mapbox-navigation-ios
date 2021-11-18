import XCTest
import MapboxDirections
import TestHelper
import Turf
import MapboxMaps
@testable import MapboxNavigation
@testable import MapboxCoreNavigation

class VanishingRouteLineTests: TestCase {
    var navigationMapView: NavigationMapView!
    
    override func setUp() {
        super.setUp()
        navigationMapView = NavigationMapView(frame: CGRect(origin: .zero, size: .iPhone6Plus))
    }
    
    override func tearDown() {
        navigationMapView = nil
        super.tearDown()
    }
    
    func getRoute() -> Route {
        let routeData = Fixture.JSONFromFileNamed(name: "short_route")
        let routeOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2DMake(-122.5237429, 37.975393),
            CLLocationCoordinate2DMake(-122.5231413, 37.9750695)
        ])
        let decoder = JSONDecoder()
        decoder.userInfo[.options] = routeOptions
        var testRoute: Route?
        XCTAssertNoThrow(testRoute = try decoder.decode(Route.self, from: routeData))
        guard let route = testRoute else {
            preconditionFailure("Route is invalid.")
        }
        
        return route
    }
    
    func getMultilegRoute() -> Route {
        let routeData = Fixture.JSONFromFileNamed(name: "multileg_route")
        let routeOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2DMake(-77.1576396, 38.7830304),
            CLLocationCoordinate2DMake(-77.1670888, 38.7756155),
            CLLocationCoordinate2DMake(-77.1534183, 38.7708948),
        ])
        let decoder = JSONDecoder()
        decoder.userInfo[.options] = routeOptions
        var testRoute: Route?
        XCTAssertNoThrow(testRoute = try decoder.decode(Route.self, from: routeData))
        guard let route = testRoute else {
            preconditionFailure("Route is invalid.")
        }
        
        return route
    }
    
    func getRouteProgress() -> RouteProgress {
        let route = getRoute()
        let routeProgress = RouteProgress(route: route, options: routeOptions, legIndex: 0, spokenInstructionIndex: 0)
        routeProgress.currentLegProgress = RouteLegProgress(leg: route.legs[0], stepIndex: 2, spokenInstructionIndex: 0)
        routeProgress.currentLegProgress.currentStepProgress = RouteStepProgress(step: route.legs[0].steps[2], spokenInstructionIndex: 0)
        return routeProgress
    }
    
    func lineGradientToString(lineGradient: Value<StyleColor>?) -> String {
        guard let halfStringFromLineGradient = lineGradient.debugDescription.components(separatedBy: "(").last,
              let stringFromLineGradient = halfStringFromLineGradient.components(separatedBy: ")").first else {
            preconditionFailure("Line gradient string is invalid.")
        }
        return stringFromLineGradient
    }
    
    func setUpCameraZoom(at zoomeLevel: CGFloat) {
        let cameraState = navigationMapView.mapView.cameraState
        let cameraOption = CameraOptions(center: cameraState.center, padding: cameraState.padding, zoom: zoomeLevel, bearing: cameraState.bearing, pitch: cameraState.pitch)
        navigationMapView.mapView.camera.ease(to: cameraOption, duration: 0.1, curve: .linear)
        
        expectation(description: "Zoom set up") {
            self.navigationMapView.mapView.cameraState.zoom == zoomeLevel
        }
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testParseRoutePoints() {
        // https://github.com/mapbox/mapbox-navigation-android/blob/0ca183f7cb7bec930521ea9bcd59d0e8e2bef165/libnavui-maps/src/test/java/com/mapbox/navigation/ui/maps/internal/route/line/MapboxRouteLineUtilsTest.kt#L1798
        let route = getMultilegRoute()
        let routePoints = navigationMapView.parseRoutePoints(route: route)
        
        // Because mapbox-directions-swift parses the route with one more duplicate coordinate in the last step of each route leg. The two leg route has two more coordinates compared with Android.
        XCTAssertEqual(routePoints.flatList.count, 130)
        XCTAssertEqual(routePoints.nestedList.flatMap{$0}.count, 15)
        XCTAssertEqual(routePoints.flatList[1].latitude, routePoints.flatList[2].latitude)
        XCTAssertEqual(routePoints.flatList[1].longitude, routePoints.flatList[2].longitude)
        XCTAssertEqual(routePoints.flatList[128].latitude, routePoints.flatList[129].latitude, accuracy: 0.000001)
        XCTAssertEqual(routePoints.flatList[128].longitude, routePoints.flatList[129].longitude, accuracy: 0.000001)
    }
    
    func testUpdateUpcomingRoutePointIndex() {
        // https://github.com/mapbox/mapbox-navigation-android/blob/0ca183f7cb7bec930521ea9bcd59d0e8e2bef165/libnavui-maps/src/test/java/com/mapbox/navigation/ui/maps/route/line/api/MapboxRouteLineApiTest.kt#L802
        let route = getRoute()
        
        navigationMapView.initPrimaryRoutePoints(route: route)
        navigationMapView.routeLineGranularDistances = nil
        XCTAssertEqual(navigationMapView.fractionTraveled, 0.0)
        
        let routeProgress = getRouteProgress()
        
        navigationMapView.updateUpcomingRoutePointIndex(routeProgress: routeProgress)
        
        // Because mapbox-directions-swift parses the route with one more duplicate coordinate in the last step of each route leg. The one leg route has one more coordinate compared with Android.
        XCTAssertEqual(navigationMapView.routeRemainingDistancesIndex, 7)
    }
    
    func testUpdateUpcomingRoutePointIndexWhenPrimaryRoutePointsIsNill() {
        // https://github.com/mapbox/mapbox-navigation-android/blob/0ca183f7cb7bec930521ea9bcd59d0e8e2bef165/libnavui-maps/src/test/java/com/mapbox/navigation/ui/maps/route/line/api/MapboxRouteLineApiTest.kt#L846
        let routeProgress = getRouteProgress()
        
        navigationMapView.updateUpcomingRoutePointIndex(routeProgress: routeProgress)
        XCTAssertNil(navigationMapView.routeRemainingDistancesIndex)
    }
    
    func testUpdateFractionTraveled() {
        // https://github.com/mapbox/mapbox-navigation-android/blob/0ca183f7cb7bec930521ea9bcd59d0e8e2bef165/libnavui-maps/src/test/java/com/mapbox/navigation/ui/maps/route/line/api/MapboxRouteLineApiTest.kt#L636
        let route = getRoute()
        let routeProgress = getRouteProgress()
        
        let coordinate = route.shape!.coordinates[1]
        navigationMapView.routeLineTracksTraversal = true
        navigationMapView.show([route])
        navigationMapView.updateUpcomingRoutePointIndex(routeProgress: routeProgress)
        navigationMapView.updateFractionTraveled(coordinate: coordinate)
        
        let expectedFractionTraveled = 0.3240769449298392
        XCTAssertEqual(navigationMapView.fractionTraveled, expectedFractionTraveled, accuracy: 0.0000000001)
    }
    
    func testUpdateRouteLineWithDifferentDistance() {
        let route = getRoute()
        let routeProgress = getRouteProgress()
        let coordinate = route.shape!.coordinates[1]
        
        navigationMapView.routes = [route]
        navigationMapView.routeLineTracksTraversal = true
        navigationMapView.show([route], legIndex: 0)
        navigationMapView.updateUpcomingRoutePointIndex(routeProgress: routeProgress)
        setUpCameraZoom(at: 5.0)
        
        navigationMapView.travelAlongRouteLine(to: coordinate)
        
        XCTAssertTrue(navigationMapView.fractionTraveled == 0.0, "Failed to avoid updating route line when the distance is smaller than 1 pixel.")
    }
    
    func testSwitchRouteLineTracksTraversalDuringNavigation() {
        let route = getRoute()
        let routeProgress = getRouteProgress()
        let coordinate = route.shape!.coordinates[1]
        
        navigationMapView.routes = [route]
        navigationMapView.routeLineTracksTraversal = true
        navigationMapView.show([route], legIndex: 0)
        navigationMapView.updateUpcomingRoutePointIndex(routeProgress: routeProgress)
        setUpCameraZoom(at: 16.0)
        
        navigationMapView.travelAlongRouteLine(to: coordinate)
        let expectedFractionTraveled = 0.3240769449298392
        let actualFractionTraveled = navigationMapView.fractionTraveled
        XCTAssertEqual(actualFractionTraveled, expectedFractionTraveled, accuracy: 0.0000000001, "Failed to update route line when routeLineTracksTraversal enabled.")
        
        let layerIdentifier = route.identifier(.route(isMainRoute: true))
        do {
            navigationMapView.routeLineTracksTraversal = false
            var layer = try navigationMapView.mapView.mapboxMap.style.layer(withId: layerIdentifier) as! LineLayer
            var gradientExpression = layer.lineGradient.debugDescription
            XCTAssertEqual(navigationMapView.fractionTraveled, 0.0)
            XCTAssert(!gradientExpression.contains(actualFractionTraveled.description), "Failed to stop vanishing effect when routeLineTracksTraversal disabled.")
            
            navigationMapView.routeLineTracksTraversal = true
            navigationMapView.updateUpcomingRoutePointIndex(routeProgress: routeProgress)
            navigationMapView.travelAlongRouteLine(to: coordinate)
            layer = try navigationMapView.mapView.mapboxMap.style.layer(withId: layerIdentifier) as! LineLayer
            gradientExpression = layer.lineGradient.debugDescription
            XCTAssert(gradientExpression.contains(actualFractionTraveled.description), "Failed to restore vanishing effect when routeLineTracksTraversal enabled.")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testRouteLineGradientWithCombinedColor() {
        let route = getRoute()
        
        navigationMapView.trafficModerateColor = navigationMapView.trafficUnknownColor
        navigationMapView.routes = [route]
        navigationMapView.routeLineTracksTraversal = true
        navigationMapView.show([route], legIndex: 0)
        
        let expectedGradientStops = [0.0 : navigationMapView.trafficUnknownColor]
        XCTAssertEqual(expectedGradientStops, navigationMapView.currentLineGradientStops, "Failed to combine the same color of congestion segment.")
        
    }

    func testSwitchCrossfadesCongestionSegments() {
        let route = getRoute()
        let routeProgress = getRouteProgress()
        let coordinate = route.shape!.coordinates[1]

        navigationMapView.trafficUnknownColor = UIColor.blue
        navigationMapView.trafficModerateColor = UIColor.red
        navigationMapView.traversedRouteColor = UIColor.clear
        setUpCameraZoom(at: 16.0)
        
        navigationMapView.routes = [route]
        navigationMapView.routeLineTracksTraversal = true
        navigationMapView.show([route], legIndex: 0)
        navigationMapView.updateUpcomingRoutePointIndex(routeProgress: routeProgress)
        navigationMapView.travelAlongRouteLine(to: coordinate)

        let fractionTrvaled = navigationMapView.fractionTraveled
        let fractionTrvaledNextDown = Double(CGFloat(fractionTrvaled).nextDown)
        
        var expectedExpressionString = "[step, [line-progress], [rgba, 0.0, 0.0, 255.0, 1.0], 0.0, [rgba, 0.0, 0.0, 0.0, 0.0], \(fractionTrvaledNextDown), [rgba, 0.0, 0.0, 0.0, 0.0], \(fractionTrvaled), [rgba, 0.0, 0.0, 255.0, 1.0], 0.9425498181625797, [rgba, 0.0, 0.0, 255.0, 1.0], 0.9425498181625799, [rgba, 255.0, 0.0, 0.0, 1.0]]"

        let layerIdentifier = route.identifier(.route(isMainRoute: true))
        do {
            var layer = try navigationMapView.mapView.mapboxMap.style.layer(withId: layerIdentifier) as! LineLayer
            var lineGradientString = lineGradientToString(lineGradient: layer.lineGradient)
            XCTAssertEqual(lineGradientString, expectedExpressionString, "Failed to apply step color transition between two different congestion level.")

            // During active navigation with `routeLineTracksTraversal` and `crossfadesCongestionSegments` both enabled, the route line should re-generate the gradient stops and update the line gradient expression when there's a location update comes in.
            expectedExpressionString = "[interpolate, [linear], [line-progress], 0.0, [rgba, 0.0, 0.0, 0.0, 0.0], \(fractionTrvaledNextDown), [rgba, 0.0, 0.0, 0.0, 0.0], \(fractionTrvaled), [rgba, 0.0, 0.0, 255.0, 1.0], 0.8482948363463217, [rgba, 0.0, 0.0, 255.0, 1.0], 0.9482948363463218, [rgba, 255.0, 0.0, 0.0, 1.0]]"
            navigationMapView.crossfadesCongestionSegments = true
            navigationMapView.travelAlongRouteLine(to: coordinate)
            
            layer = try navigationMapView.mapView.mapboxMap.style.layer(withId: layerIdentifier) as! LineLayer
            lineGradientString = lineGradientToString(lineGradient: layer.lineGradient)
            XCTAssertEqual(lineGradientString, expectedExpressionString, "Failed to apply soft color transition between two different congestion level.")
            
            // During active navigation with `crossfadesCongestionSegments` enabled but `routeLineTracksTraversal` disabled, the route line should re-generate the route line directly.
            expectedExpressionString = "[step, [line-progress], [rgba, 0.0, 0.0, 255.0, 1.0], 0.0, [rgba, 0.0, 0.0, 255.0, 1.0], 0.9425498181625797, [rgba, 0.0, 0.0, 255.0, 1.0], 0.9425498181625799, [rgba, 255.0, 0.0, 0.0, 1.0]]"
            navigationMapView.routeLineTracksTraversal = false
            navigationMapView.crossfadesCongestionSegments = false
            
            layer = try navigationMapView.mapView.mapboxMap.style.layer(withId: layerIdentifier) as! LineLayer
            lineGradientString = lineGradientToString(lineGradient: layer.lineGradient)
            XCTAssertEqual(lineGradientString, expectedExpressionString, "Failed to apply step color transition between two different congestion level and show a whole new route line.")
        } catch {
            XCTFail(error.localizedDescription)
        }
    }
    
    func testProjectedDistance() {
        // https://github.com/mapbox/mapbox-navigation-android/blob/0ca183f7cb7bec930521ea9bcd59d0e8e2bef165/libnavui-maps/src/test/java/com/mapbox/navigation/ui/maps/internal/route/line/MapboxRouteLineUtilsTest.kt#L257
        
        let startCoordinate = CLLocationCoordinate2D(latitude: 37.974092, longitude: -122.525212)
        let endCoordinate = CLLocationCoordinate2D(latitude: 37.974569579999944, longitude: -122.52509389295653)
        
        let distance = startCoordinate.projectedDistance(to: endCoordinate)
        let expectedDistance = 0.0000017145850113848236
        XCTAssertEqual(distance, expectedDistance, "Failed to calculate the right project distance.")
    }
    
    func testRouteLineGradientWithoutCongestionLevel() {
        let route = getRoute()
        route.legs.first!.segmentCongestionLevels = nil
        route.legs.first!.segmentNumericCongestionLevels = nil
        XCTAssertNil(route.legs.first!.resolvedCongestionLevels, "Failed to get nil resolvedCongestionLevels from route.")

        let congestionFeatures = route.congestionFeatures(legIndex: 0)
        let currentLineGradientStops = navigationMapView.routeLineGradient(congestionFeatures, fractionTraveled: 0.0)
        XCTAssertEqual(currentLineGradientStops[0.0], navigationMapView.trafficUnknownColor, "Failed to use trafficUnknownColor for route line when no congestion level found.")
    }
}
