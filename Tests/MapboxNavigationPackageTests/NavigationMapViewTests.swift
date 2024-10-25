import Combine
import MapboxDirections
import MapboxMaps
@testable import MapboxNavigationCore
import TestHelper
import Turf
import XCTest

@MainActor
class NavigationMapViewTests: TestCase {
    var navigationRoutes: NavigationRoutes!
    var navigationMapView: NavigationMapView!
    var mapboxMap: MapboxMap!
    var routeProgressPublisher: CurrentValueSubject<RouteProgress?, Never>!
    var subscriptions: Set<AnyCancellable>!

    let options: NavigationRouteOptions = .init(coordinates: [
        CLLocationCoordinate2D(latitude: 40.311012, longitude: -112.47926),
        CLLocationCoordinate2D(latitude: 29.99908, longitude: -102.828197),
    ])

    override func setUp() async throws {
        try await super.setUp()

        navigationRoutes = await Fixture.navigationRoutes(from: "route-with-instructions", options: options)
        subscriptions = []
        routeProgressPublisher = .init(nil)

        navigationMapView = NavigationMapView(
            location: locationPublisher.eraseToAnyPublisher(),
            routeProgress: routeProgressPublisher.eraseToAnyPublisher()
        )
        navigationMapView.frame = UIScreen.main.bounds
        guard let mapboxMap = navigationMapView.mapView.mapboxMap else {
            XCTFail("Should have non-nil mapboxMap")
            return
        }
        self.mapboxMap = mapboxMap
    }

    override func tearDown() {
        navigationMapView = nil
        super.tearDown()
    }

    let intersections = [
        Intersection(
            location: CLLocationCoordinate2D(latitude: 38.878206, longitude: -77.037265),
            headings: [],
            approachIndex: 0,
            outletIndex: 0,
            outletIndexes: .init(integer: 0),
            approachLanes: nil,
            usableApproachLanes: nil,
            preferredApproachLanes: nil,
            usableLaneIndication: nil,
            yieldSign: true
        ),
        Intersection(
            location: CLLocationCoordinate2D(latitude: 38.910736, longitude: -76.966906),
            headings: [],
            approachIndex: 0,
            outletIndex: 0,
            outletIndexes: .init(integer: 0),
            approachLanes: nil,
            usableApproachLanes: nil,
            preferredApproachLanes: nil,
            usableLaneIndication: nil,
            stopSign: true
        ),
    ]

    let coordinates: [CLLocationCoordinate2D] = [
        CLLocationCoordinate2D(latitude: 0, longitude: 0),
        CLLocationCoordinate2D(latitude: 1, longitude: 1),
        CLLocationCoordinate2D(latitude: 2, longitude: 2),
        CLLocationCoordinate2D(latitude: 3, longitude: 3),
        CLLocationCoordinate2D(latitude: 4, longitude: 4),
        CLLocationCoordinate2D(latitude: 5, longitude: 5),
    ]

    func testETACalloutsAlongActiveGuidanceRouteDisabled() async {
        let navigationRouteOptions = NavigationRouteOptions(coordinates: [
            CLLocationCoordinate2D(latitude: 37.330536, longitude: -122.030373),
            CLLocationCoordinate2D(latitude: 37.412221, longitude: -121.887143),
            CLLocationCoordinate2D(latitude: 37.493855, longitude: -121.936005),
        ])

        let routeWithAlternatives = await Fixture.navigationRoutes(
            from: "multileg-route-alternatives",
            options: navigationRouteOptions
        )

        navigationMapView.showcase(navigationRoutes)

        XCTAssertFalse(
            navigationMapView.routeAnnotationKinds.isEmpty,
            "`navigationMapView` should have route annotations set."
        )

        navigationMapView.showsRelativeDurationsOnAlternativeManuever = false

        routeProgressPublisher.send(
            RouteProgress(
                navigationRoutes: routeWithAlternatives,
                waypoints: navigationRouteOptions.waypoints,
                congestionConfiguration: .default
            )
        )

        XCTAssertTrue(
            navigationMapView.routeAnnotationKinds.isEmpty,
            "`navigationMapView` should have no route annotations set."
        )
    }

    func testNavigationMapViewCombineWithSimilarCongestions() {
        let congestionSegments = coordinates.combined([
            .low,
            .low,
            .low,
            .low,
            .low,
        ])

        XCTAssertEqual(congestionSegments.count, 1)
        XCTAssertEqual(congestionSegments[0].0.count, 6)
        XCTAssertEqual(congestionSegments[0].1, .low)
    }

    func testNavigationMapViewCombineWithDissimilarCongestions() {
        let congestionSegmentsSevere = coordinates.combined([
            .low,
            .low,
            .severe,
            .low,
            .low,
        ])

        // The severe breaks the trend of .low.
        // Any time the current congestion level is different than the previous segment, we have to create a new
        // congestion segment.
        XCTAssertEqual(congestionSegmentsSevere.count, 3)

        XCTAssertEqual(congestionSegmentsSevere[0].0.count, 3)
        XCTAssertEqual(congestionSegmentsSevere[1].0.count, 2)
        XCTAssertEqual(congestionSegmentsSevere[2].0.count, 3)

        XCTAssertEqual(congestionSegmentsSevere[0].1, .low)
        XCTAssertEqual(congestionSegmentsSevere[1].1, .severe)
        XCTAssertEqual(congestionSegmentsSevere[2].1, .low)
    }

    func testNavigationMapViewCombineWithSimilarRoadClasses() {
        let congestionSegments = coordinates.combined([
            .restricted,
            [.restricted, .toll],
            [.restricted, .toll],
            .restricted,
            .restricted,
        ], combiningRoadClasses: .restricted)

        XCTAssertEqual(congestionSegments.count, 1)
        XCTAssertEqual(congestionSegments[0].0.count, 6)
        XCTAssertEqual(congestionSegments[0].1, .restricted)
    }

    func testNavigationMapViewCombineWithDissimilarRoadClasses() {
        let congestionSegmentsSevere = coordinates.combined([
            .restricted,
            [.restricted, .ferry],
            .ferry,
            [.restricted, .ferry],
            .restricted,
        ], combiningRoadClasses: .restricted)

        // The ferry breaks the trend of .restricted.
        // Any time the current road class is different than the previous segment, we have to create a new road class
        // segment.
        XCTAssertEqual(congestionSegmentsSevere.count, 3)

        XCTAssertEqual(congestionSegmentsSevere[0].0.count, 3)
        XCTAssertEqual(congestionSegmentsSevere[1].0.count, 2)
        XCTAssertEqual(congestionSegmentsSevere[2].0.count, 3)

        XCTAssertEqual(congestionSegmentsSevere[0].1, .restricted)
        XCTAssertEqual(congestionSegmentsSevere[1].1, RoadClasses())
        XCTAssertEqual(congestionSegmentsSevere[2].1, .restricted)
    }

    func testInitWithCarPlayCamera() {
        let navigationMapView = NavigationMapView(
            location: locationPublisher.eraseToAnyPublisher(),
            routeProgress: routeProgressPublisher.eraseToAnyPublisher(),
            navigationCameraType: .carPlay
        )
        XCTAssertTrue(navigationMapView.navigationCamera.viewportDataSource is CarPlayViewportDataSource)
    }

    func testEnablePredictiveCaching() {
        let spy = PredictiveCacheManagerSpy()
        navigationMapView = NavigationMapView(
            location: locationPublisher.eraseToAnyPublisher(),
            routeProgress: routeProgressPublisher.eraseToAnyPublisher(),
            predictiveCacheManager: spy
        )
        XCTAssertEqual(spy.passedMapView, navigationMapView.mapView)
    }

    func testUpdateIntersectionAnnotationsIfCorrectIndex() {
        var progress = RouteProgress(
            navigationRoutes: navigationRoutes,
            waypoints: [],
            congestionConfiguration: .default
        )
        let status = TestNavigationStatusProvider.createActiveStatus(intersectionIndex: 1)
        progress.update(using: status)
        progress.currentLegProgress.currentStepProgress
            .intersectionsIncludingUpcomingManeuverIntersection = intersections

        navigationMapView.mapStyleManager.onStyleLoaded()
        navigationMapView.updateRouteLine(routeProgress: progress)

        let annotation = FeatureIds.IntersectionAnnotation()
        let source = try? mapboxMap.source(withId: annotation.source) as? GeoJSONSource
        let layer = try? mapboxMap.layer(withId: annotation.layer) as? SymbolLayer

        XCTAssertNotNil(source)
        XCTAssertNotNil(layer)
        XCTAssertEqual(layer?.source, annotation.source)
    }

    func testUpdateIntersectionAnnotationsIfIncorrectIndex() {
        var progress = RouteProgress(
            navigationRoutes: navigationRoutes,
            waypoints: [],
            congestionConfiguration: .default
        )
        let status = TestNavigationStatusProvider.createActiveStatus(intersectionIndex: 10)
        progress.update(using: status)
        progress.currentLegProgress.currentStepProgress.intersectionsIncludingUpcomingManeuverIntersection = []

        navigationMapView.mapStyleManager.onStyleLoaded()
        navigationMapView.updateRouteLine(routeProgress: progress)

        let annotation = FeatureIds.IntersectionAnnotation()
        let source = try? mapboxMap.source(withId: annotation.source) as? GeoJSONSource
        let layer = try? mapboxMap.layer(withId: annotation.layer) as? SymbolLayer

        XCTAssertNotNil(source)
        XCTAssertNotNil(layer)
        XCTAssertEqual(layer?.source, annotation.source)
    }

    func testUpdateIntersectionAnnotationsIfRouteComplete() {
        var progress = RouteProgress(
            navigationRoutes: navigationRoutes,
            waypoints: [],
            congestionConfiguration: .default
        )
        let route = navigationRoutes.mainRoute.route

        let status0 = TestNavigationStatusProvider.createActiveStatus(intersectionIndex: 1)
        progress.update(using: status0)
        progress.currentLegProgress.currentStepProgress
            .intersectionsIncludingUpcomingManeuverIntersection = intersections

        navigationMapView.mapStyleManager.onStyleLoaded()
        // adds intersections
        navigationMapView.updateRouteLine(routeProgress: progress)

        let stepIndex = route.legs[0].steps.count - 1
        let status = TestNavigationStatusProvider.createActiveStatus(stepIndex: UInt32(stepIndex))
        progress.currentLegProgress.update(using: status)
        progress.currentLegProgress.userHasArrivedAtWaypoint = true

        navigationMapView.updateRouteLine(routeProgress: progress)

        let annotation = FeatureIds.IntersectionAnnotation()
        XCTAssertFalse(mapboxMap.layerExists(withId: annotation.layer))
        XCTAssertFalse(mapboxMap.sourceExists(withId: annotation.source))
    }
}
