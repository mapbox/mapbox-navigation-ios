import _MapboxNavigationTestHelpers
import MapboxDirections
import MapboxMaps
@testable import MapboxNavigationCore
import Turf
import XCTest

class RouteCalloutsFeatureTests: BaseTestCase {
    var mapLayersOrder: MapLayersOrder!
    var mapView: MapView!
    var navigationRoutes: NavigationRoutes!
    var mapStyleConfig: MapStyleConfig!

    @MainActor
    override func setUp() async throws {
        try await super.setUp()

        mapView = MapView(frame: .init(x: 0, y: 0, width: 100, height: 100))
        mapLayersOrder = MapLayersOrder(builder: {}, legacyPosition: nil)
        navigationRoutes = await .mock(alternativeRoutes: [.mock()])
        mapStyleConfig = .mock(fixedRouteCalloutPosition: .disabled)
    }

    @MainActor
    func testHandleAlternativeRouteOffsetIfAnnotateAtManeuverOnStart() {
        addAnnotations(annotateAtManeuver: true)
        XCTAssertEqual(mapView.viewAnnotations.allAnnotations.count, 1)

        let route = navigationRoutes.alternativeRoutes[0].route
        let annotation = mapView.viewAnnotations.allAnnotations[0]
        XCTAssertEqual(annotation.annotatedFeature, route.geometry(for: 0.01..<0.05))
    }

    @MainActor
    func testHandleAlternativeRouteOffsetIfAnnotateAtManeuverInMiddle() {
        let alternative = alternative(withDeviationIndex: 9)
        navigationRoutes.allAlternativeRoutesWithIgnored = [alternative]
        addAnnotations(annotateAtManeuver: true)
        XCTAssertEqual(mapView.viewAnnotations.allAnnotations.count, 1)

        let route = navigationRoutes.alternativeRoutes[0].route
        let annotation = mapView.viewAnnotations.allAnnotations[0]
        let lower = alternative.deviationOffset() + 0.01
        XCTAssertEqual(annotation.annotatedFeature, route.geometry(for: lower..<(lower + 0.04)))
    }

    @MainActor
    func testHandleAlternativeRouteOffsetIfAnnotateAtManeuverOnFinish() {
        let alternative = alternative(withDeviationIndex: 2)
        navigationRoutes.allAlternativeRoutesWithIgnored = [alternative]
        addAnnotations(annotateAtManeuver: true)
        XCTAssertEqual(mapView.viewAnnotations.allAnnotations.count, 1)

        let route = navigationRoutes.alternativeRoutes[0].route
        let annotation = mapView.viewAnnotations.allAnnotations[0]
        let lower = alternative.deviationOffset() + 0.01
        XCTAssertEqual(annotation.annotatedFeature, route.geometry(for: lower..<1.0))
    }

    @MainActor
    func testHandleAlternativeRouteOffsetIfNotAnnotateAtManeuverOnStart() {
        addAnnotations(annotateAtManeuver: false)
        XCTAssertEqual(mapView.viewAnnotations.allAnnotations.count, 1)

        let route = navigationRoutes.alternativeRoutes[0].route
        let annotation = mapView.viewAnnotations.allAnnotations[0]
        XCTAssertEqual(annotation.annotatedFeature, route.geometry(for: 0.01..<0.8))
    }

    @MainActor
    func testHandleAlternativeRouteOffsetIfNotAnnotateAtManeuverInMiddle() {
        let alternative = alternative(withDeviationIndex: 9)
        navigationRoutes.allAlternativeRoutesWithIgnored = [alternative]
        addAnnotations(annotateAtManeuver: false)

        let route = navigationRoutes.alternativeRoutes[0].route
        let annotation = mapView.viewAnnotations.allAnnotations[0]
        let lower = alternative.deviationOffset() + 0.01
        XCTAssertEqual(annotation.annotatedFeature, route.geometry(for: lower..<0.8))
    }

    @MainActor
    func testHandleAlternativeRouteOffsetIfNotAnnotateAtManeuverOnFinish() {
        let alternative = alternative(withDeviationIndex: 2)
        navigationRoutes.allAlternativeRoutesWithIgnored = [alternative]
        addAnnotations(annotateAtManeuver: false)

        let route = navigationRoutes.alternativeRoutes[0].route
        let annotation = mapView.viewAnnotations.allAnnotations[0]
        let lower = alternative.deviationOffset() + 0.01
        XCTAssertEqual(annotation.annotatedFeature, route.geometry(for: lower..<(lower + 0.01)))
    }

    @MainActor
    func testHandleAlternativeRouteOffsetIfNotAnnotateAtManeuverOnVeryFinish() {
        let alternative = AlternativeRoute.mock(
            alternativeRoute: .mock(shape: .mock(delta: (0.01, -0.01), count: 2000)),
            nativeRouteAlternative: .mock(alternativeRouteFork: .mock(geometryIndex: 1999))
        )
        navigationRoutes.allAlternativeRoutesWithIgnored = [alternative]
        addAnnotations(annotateAtManeuver: false)

        let route = navigationRoutes.alternativeRoutes[0].route
        let annotation = mapView.viewAnnotations.allAnnotations[0]
        XCTAssertEqual(annotation.annotatedFeature, route.geometry(for: 0.99..<1.0))
    }

    @MainActor
    private func alternative(withDeviationIndex deviationIndex: Int) -> AlternativeRoute {
        let index = UInt32(navigationRoutes.alternativeRoutes[0].route.shape!.coordinates.count - deviationIndex)
        return AlternativeRoute.mock(
            nativeRouteAlternative: .mock(alternativeRouteFork: .mock(geometryIndex: index))
        )
    }

    @MainActor
    private func addAnnotations(annotateAtManeuver: Bool) {
        let feature = RouteCalloutsFeature(
            for: navigationRoutes,
            showMainRoute: false,
            showAlternatives: true,
            isRelative: true,
            annotateAtManeuver: annotateAtManeuver,
            mapStyleConfig: mapStyleConfig
        )
        feature.add(to: mapView, order: &mapLayersOrder)
    }
}

extension Route {
    fileprivate func geometry(for range: Range<Double>) -> AnnotatedFeature? {
        guard let geometry = shape?.trimmed(
            from: distance * range.lowerBound,
            to: distance * range.upperBound
        )?.geometry else {
            return nil
        }
        return .geometry(geometry)
    }
}
