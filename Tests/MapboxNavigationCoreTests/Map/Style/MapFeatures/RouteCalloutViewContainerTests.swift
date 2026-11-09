import _MapboxNavigationTestHelpers
import MapboxDirections
import MapboxMaps
@_spi(ExperimentalMapboxAPI) @_spi(MapboxInternal) @testable import MapboxNavigationCore
import Turf
import UIKit
import XCTest

class RouteCalloutViewContainerTests: BaseTestCase {
    static let layerID = "route-layer"
    private let route = Route.mock()

    func testPlacementDefaultsToAutomatic() {
        let container = container()
        XCTAssertEqual(container.placement, .automatic)
    }

    func testFixedPlacementIsClampedToUnitRange() {
        XCTAssertEqual(container(placement: .fixed(0.3)).placement, .fixed(0.3))
        XCTAssertEqual(container(placement: .fixed(1.5)).placement, .fixed(1.0))
        XCTAssertEqual(container(placement: .fixed(-0.5)).placement, .fixed(0.0))
    }

    @MainActor
    func testAutomaticPlacementAnnotatesAllowedRangeOfRoute() {
        let annotation = makeViewAnnotation(allowedRouteOffsetRange: 0.2...0.8, placement: .automatic)

        let expected = route.shape?.trimmed(from: route.distance * 0.2, to: route.distance * 0.8)?.geometry
        XCTAssertEqual(annotation.annotatedFeature, expected.map { .geometry($0) })
    }

    @MainActor
    func testFixedPlacementAnnotatesFractionOfAllowedRange() {
        let annotation = makeViewAnnotation(allowedRouteOffsetRange: 0.2...0.6, placement: .fixed(0.25))

        XCTAssertEqual(annotation.annotatedFeature, point(atRouteOffset: 0.3))
    }

    @MainActor
    func testFixedPlacementAtRangeBounds() {
        let start = makeViewAnnotation(allowedRouteOffsetRange: 0.2...0.6, placement: .fixed(0))
        let end = makeViewAnnotation(allowedRouteOffsetRange: 0.2...0.6, placement: .fixed(1))

        XCTAssertEqual(start.annotatedFeature, point(atRouteOffset: 0.2))
        XCTAssertEqual(end.annotatedFeature, point(atRouteOffset: 0.6))
    }

    @MainActor
    func testOutOfRangeFixedPlacementAnnotatesRangeBound() {
        let annotation = makeViewAnnotation(allowedRouteOffsetRange: 0.2...0.6, placement: .fixed(1.5))

        XCTAssertEqual(annotation.annotatedFeature, point(atRouteOffset: 0.6))
    }

    @MainActor
    func testAnnotationFallsBackToLayerWithoutRouteShape() {
        let route = Route.mock(shape: nil)
        let annotation = container(placement: .fixed(0.5))
            .makeViewAnnotation(for: route, fallbackLayerId: Self.layerID, anchors: [])

        XCTAssertEqual(annotation.annotatedFeature, .layerFeature(layerId: Self.layerID))
    }

    private func container(
        allowedRouteOffsetRange: ClosedRange<Double> = RouteCalloutViewContainer.defaultAllowedRouteOffsetRange,
        placement: RouteCalloutViewContainer.Placement? = nil
    ) -> RouteCalloutViewContainer {
        if let placement {
            RouteCalloutViewContainer(
                view: UIView(),
                allowedRouteOffsetRange: allowedRouteOffsetRange,
                placement: placement
            ) { _ in }
        } else {
            RouteCalloutViewContainer(view: UIView(), allowedRouteOffsetRange: allowedRouteOffsetRange) { _ in }
        }
    }

    @MainActor
    private func makeViewAnnotation(
        allowedRouteOffsetRange: ClosedRange<Double>,
        placement: RouteCalloutViewContainer.Placement
    ) -> ViewAnnotation {
        container(allowedRouteOffsetRange: allowedRouteOffsetRange, placement: placement)
            .makeViewAnnotation(for: route, fallbackLayerId: Self.layerID, anchors: [])
    }

    private func point(atRouteOffset offset: Double) -> AnnotatedFeature? {
        route.shape?.coordinateFromStart(distance: route.distance * offset).map { .geometry(Point($0)) }
    }
}
