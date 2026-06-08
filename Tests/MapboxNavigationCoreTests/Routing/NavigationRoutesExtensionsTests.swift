@testable import _MapboxNavigationTestHelpers
import CoreLocation
import MapboxDirections
@testable import MapboxNavigationCore
import MapboxNavigationNative_Private
import XCTest

final class NavigationRoutesExtensionsTests: TestCase {
    // MARK: - NavigationRoute.isRefreshed(comparedTo:)

    func testIsNotRefreshedForDifferentRouteIds() {
        XCTAssertFalse(makeRoute(id: "A").isRefreshed(comparedTo: makeRoute(id: "B")))
    }

    func testIsNotRefreshedWhenDataIsUnchanged() {
        var leg = RouteLeg.mock()
        leg.segmentCongestionLevels = [.low, .moderate]
        XCTAssertFalse(makeRoute(id: "A", legs: [leg]).isRefreshed(comparedTo: makeRoute(id: "A", legs: [leg])))
    }

    func testIsRefreshedWhenExpectedTravelTimeChanges() {
        let before = makeRoute(id: "A", expectedTravelTime: 100)
        let after = makeRoute(id: "A", expectedTravelTime: 200)
        XCTAssertTrue(before.isRefreshed(comparedTo: after))
    }

    func testIsRefreshedWhenSegmentCongestionLevelsChange() {
        var legBefore = RouteLeg.mock()
        legBefore.segmentCongestionLevels = [.low]
        var legAfter = RouteLeg.mock()
        legAfter.segmentCongestionLevels = [.severe]
        let before = makeRoute(id: "A", legs: [legBefore])
        let after = makeRoute(id: "A", legs: [legAfter])
        XCTAssertTrue(before.isRefreshed(comparedTo: after))
    }

    func testIsRefreshedWhenSegmentNumericCongestionLevelsChange() {
        var legBefore = RouteLeg.mock()
        legBefore.segmentNumericCongestionLevels = [10, 90]
        var legAfter = RouteLeg.mock()
        legAfter.segmentNumericCongestionLevels = [1, 90]
        let before = makeRoute(id: "A", legs: [legBefore])
        let after = makeRoute(id: "A", legs: [legAfter])
        XCTAssertTrue(before.isRefreshed(comparedTo: after))
    }

    func testIsRefreshedWhenIncidentsChange() {
        var legBefore = RouteLeg.mock()
        legBefore.incidents = []
        var legAfter = RouteLeg.mock()
        legAfter.incidents = [.mock()]
        let before = makeRoute(id: "A", legs: [legBefore])
        let after = makeRoute(id: "A", legs: [legAfter])
        XCTAssertTrue(before.isRefreshed(comparedTo: after))

        legBefore.incidents = [.mock(identifier: "incident-1")]
        legAfter.incidents = [.mock(identifier: "incident-2")]
        let before2 = makeRoute(id: "A", legs: [legBefore])
        let after2 = makeRoute(id: "A", legs: [legAfter])
        XCTAssertTrue(before2.isRefreshed(comparedTo: after2))
    }

    func testIsRefreshedWhenClosuresChange() {
        var legBefore = RouteLeg.mock()
        legBefore.closures = []
        var legAfter = RouteLeg.mock()
        legAfter.closures = [.mock(startIndex: 2, endIndex: 3)]
        let before = makeRoute(id: "A", legs: [legBefore])
        let after = makeRoute(id: "A", legs: [legAfter])
        XCTAssertTrue(before.isRefreshed(comparedTo: after))

        legBefore.closures = [.mock(startIndex: 0, endIndex: 1)]
        let before2 = makeRoute(id: "A", legs: [legBefore])
        XCTAssertTrue(before2.isRefreshed(comparedTo: after))
    }

    func testIsNotRefreshedWhenNilAndEmptySegmentCongestionLevels() {
        var legWithNil = RouteLeg.mock()
        legWithNil.segmentCongestionLevels = nil
        var legWithEmpty = RouteLeg.mock()
        legWithEmpty.segmentCongestionLevels = []
        let before = makeRoute(id: "A", legs: [legWithNil])
        let after = makeRoute(id: "A", legs: [legWithEmpty])
        XCTAssertFalse(before.isRefreshed(comparedTo: after))
    }

    func testIsNotRefreshedWhenNilAndEmptySegmentNumericCongestionLevels() {
        var legWithNil = RouteLeg.mock()
        legWithNil.segmentNumericCongestionLevels = nil
        var legWithEmpty = RouteLeg.mock()
        legWithEmpty.segmentNumericCongestionLevels = []
        let before = makeRoute(id: "A", legs: [legWithNil])
        let after = makeRoute(id: "A", legs: [legWithEmpty])
        XCTAssertFalse(before.isRefreshed(comparedTo: after))
    }

    func testIsNotRefreshedWhenNilAndEmptyIncidents() {
        var legWithNil = RouteLeg.mock()
        legWithNil.incidents = nil
        var legWithEmpty = RouteLeg.mock()
        legWithEmpty.incidents = []
        let before = makeRoute(id: "A", legs: [legWithNil])
        let after = makeRoute(id: "A", legs: [legWithEmpty])
        XCTAssertFalse(before.isRefreshed(comparedTo: after))
    }

    func testIsRefreshedWhenOnlyFirstLegSegmentCongestionLevelsChange() {
        var leg1Before = RouteLeg.mock()
        leg1Before.segmentCongestionLevels = [.low]
        var leg1After = RouteLeg.mock()
        leg1After.segmentCongestionLevels = [.severe]
        let unchangedLeg = RouteLeg.mock()
        let before = makeRoute(id: "A", legs: [leg1Before, unchangedLeg])
        let after = makeRoute(id: "A", legs: [leg1After, unchangedLeg])
        XCTAssertTrue(before.isRefreshed(comparedTo: after))
    }

    func testIsRefreshedWhenOnlyFirstLegSegmentNumericCongestionLevelsChange() {
        var leg1Before = RouteLeg.mock()
        leg1Before.segmentNumericCongestionLevels = [10, 90]
        var leg1After = RouteLeg.mock()
        leg1After.segmentNumericCongestionLevels = [1, 90]
        let unchangedLeg = RouteLeg.mock()
        let before = makeRoute(id: "A", legs: [leg1Before, unchangedLeg])
        let after = makeRoute(id: "A", legs: [leg1After, unchangedLeg])
        XCTAssertTrue(before.isRefreshed(comparedTo: after))
    }

    func testIsRefreshedWhenOnlyFirstLegIncidentsChange() {
        var leg1Before = RouteLeg.mock()
        leg1Before.incidents = [.mock(identifier: "incident-1")]
        var leg1After = RouteLeg.mock()
        leg1After.incidents = [.mock(identifier: "incident-2")]
        let unchangedLeg = RouteLeg.mock()
        let before = makeRoute(id: "A", legs: [unchangedLeg, leg1Before])
        let after = makeRoute(id: "A", legs: [unchangedLeg, leg1After])
        XCTAssertTrue(before.isRefreshed(comparedTo: after))
    }

    func testIsRefreshedWhenOnlyFirstLegClosuresChange() {
        var leg1Before = RouteLeg.mock()
        leg1Before.closures = [.mock(startIndex: 0, endIndex: 1)]
        var leg1After = RouteLeg.mock()
        leg1After.closures = [.mock(startIndex: 2, endIndex: 3)]
        let unchangedLeg = RouteLeg.mock()
        let before = makeRoute(id: "A", legs: [unchangedLeg, leg1Before])
        let after = makeRoute(id: "A", legs: [unchangedLeg, leg1After])
        XCTAssertTrue(before.isRefreshed(comparedTo: after))

        let before2 = makeRoute(id: "A", legs: [leg1Before])
        let after2 = makeRoute(id: "A", legs: [leg1After, unchangedLeg])
        XCTAssertTrue(before2.isRefreshed(comparedTo: after2))
    }

    func testIsNotRefreshedWhenNilAndEmptyClosures() {
        var legWithNil = RouteLeg.mock()
        legWithNil.closures = nil
        var legWithEmpty = RouteLeg.mock()
        legWithEmpty.closures = []
        let before = makeRoute(id: "A", legs: [legWithNil])
        let after = makeRoute(id: "A", legs: [legWithEmpty])
        XCTAssertFalse(before.isRefreshed(comparedTo: after))
    }

    // MARK: - NavigationRoutes.areRefreshed(comparedTo:)

    func testAreNotRefreshedWhenNoChange() async {
        let route = makeRoute(id: "main")
        let routes1 = await NavigationRoutes.mock(mainRoute: route)
        let routes2 = await NavigationRoutes.mock(mainRoute: route)
        XCTAssertFalse(routes1.areRefreshed(comparedTo: routes2))
    }

    func testAreNotRefreshedWhenNoChangeAndAlternatives() async {
        let route = makeRoute(id: "main")
        let alternative = makeAlternative(id: "A")
        let routes1 = await NavigationRoutes.mock(mainRoute: .mock(), alternativeRoutes: [alternative])
        let routes2 = await NavigationRoutes.mock(mainRoute: route, alternativeRoutes: [alternative])
        XCTAssertFalse(routes1.areRefreshed(comparedTo: routes2))
    }

    func testAreRefreshedWhenMainRouteIsRefreshedButHasNoAlternatives() async {
        let routes1 = await NavigationRoutes.mock(mainRoute: makeRoute(id: "main", expectedTravelTime: 100))
        let routes2 = await NavigationRoutes.mock(mainRoute: makeRoute(id: "main", expectedTravelTime: 200))
        XCTAssertTrue(routes1.areRefreshed(comparedTo: routes2))
    }

    func testAreRefreshedWhenMainRouteIsRefreshedButAlternativeIsUnchanged() async {
        let alternative = makeAlternative(id: "alt")
        let routes1 = await NavigationRoutes.mock(
            mainRoute: makeRoute(id: "main", expectedTravelTime: 100),
            alternativeRoutes: [alternative]
        )
        let routes2 = await NavigationRoutes.mock(
            mainRoute: makeRoute(id: "main", expectedTravelTime: 200),
            alternativeRoutes: [alternative]
        )
        XCTAssertTrue(routes1.areRefreshed(comparedTo: routes2))
    }

    func testAreRefreshedWhenAlternativeHasNoMatchingIdInOther() async {
        let routes1 = await NavigationRoutes.mock(
            mainRoute: makeRoute(id: "main", expectedTravelTime: 100),
            alternativeRoutes: [makeAlternative(id: "alt-A")]
        )
        let routes2 = await NavigationRoutes.mock(
            mainRoute: makeRoute(id: "main", expectedTravelTime: 200),
            alternativeRoutes: [makeAlternative(id: "alt-B")]
        )
        XCTAssertTrue(routes1.areRefreshed(comparedTo: routes2))
    }

    func testAreRefreshedWhenMainRouteAndAlternativeAreRefreshed() async {
        let routes1 = await NavigationRoutes.mock(
            mainRoute: makeRoute(id: "main", expectedTravelTime: 100),
            alternativeRoutes: [makeAlternative(id: "alt", expectedTravelTime: 100)]
        )
        let routes2 = await NavigationRoutes.mock(
            mainRoute: makeRoute(id: "main", expectedTravelTime: 200),
            alternativeRoutes: [makeAlternative(id: "alt", expectedTravelTime: 200)]
        )
        XCTAssertTrue(routes1.areRefreshed(comparedTo: routes2))
    }

    // MARK: - Utils

    private func makeRoute(
        id: String,
        legs: [RouteLeg] = [.mock()],
        expectedTravelTime: TimeInterval = 100
    ) -> NavigationRoute {
        .mock(
            route: .mock(legs: legs, expectedTravelTime: expectedTravelTime),
            nativeRoute: RouteInterfaceMock(routeId: id)
        )
    }

    private func makeAlternative(
        id: String,
        legs: [RouteLeg] = [.mock()],
        expectedTravelTime: TimeInterval = 100
    ) -> AlternativeRoute {
        let route = Route.mock(legs: legs, expectedTravelTime: expectedTravelTime)
        return .mock(
            alternativeRoute: route,
            nativeRouteAlternative: .mock(route: RouteInterfaceMock(route: route, routeId: id))
        )
    }
}

extension RouteLeg.Closure {
    fileprivate static func mock(startIndex: Int = 0, endIndex: Int = 1) -> Self {
        let string = "{\"geometry_index_start\":\(startIndex),\"geometry_index_end\":\(endIndex)}"
        return try! JSONDecoder().decode(Self.self, from: string.data(using: .utf8)!)
    }
}
