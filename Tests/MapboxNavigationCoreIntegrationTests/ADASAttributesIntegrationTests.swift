@testable import _MapboxNavigationTestHelpers
import Combine
import MapboxDirections
@testable import MapboxNavigationCore
import MapboxNavigationNative_Private
import XCTest

final class ADASAttributesIntegrationTests: BaseIntegrationTest {
    override func makeInitialLocation() -> CLLocation {
        CLLocation(latitude: 48.412623, longitude: 10.432769)
    }

    override func makeBaseCoreConfig(credentials: NavigationCoreApiConfiguration) -> CoreConfig {
        let testTilestoreURL = URL(string: "AdasTilestore", relativeTo: Bundle.module.resourceURL)!

        return CoreConfig(
            credentials: credentials,
            historyRecordingConfig: .init(), // TODO: remove history recorder after NN-4537 is resolved
            electronicHorizonConfig: .init(
                length: 500,
                expansionLevel: 1,
                branchLength: 50,
                minTimeDeltaBetweenUpdates: nil,
                enableEnhancedDataAlongEH: true
            ),
            tilesVersion: "2026_02_01-14_08_13",
            tilestoreConfig: .custom(testTilestoreURL)
        )
    }

    func testAdasDataFetched() async {
        var subscriptions: [AnyCancellable] = []
        let adasExpectation = expectation(description: "EH event reported")
        var adasAttributes: RoadGraph.Edge.ADASAttributes?

        await navigationProvider.tripSession().startFreeDrive()
        let roadGraph = await navigationProvider.electronicHorizon().roadMatching.roadGraph

        await navigationProvider.electronicHorizon().eHorizonEvents
            .compactMap { $0.event as? EHorizonStatus.Events.PositionUpdated }
            .sink { event in
                let edgeIdentifier = event.startingEdge.identifier
                guard let attributes = roadGraph.adasAttributes(edgeIdentifier: edgeIdentifier) else {
                    return
                }
                adasAttributes = attributes
                adasExpectation.fulfill()
            }.store(in: &subscriptions)

        await navigationProvider.electronicHorizon().startUpdatingEHorizon()
        await simulateLocations(
            Array(
                repeating: makeInitialLocation(),
                count: 5
            ).shiftedToPresent()
        )
        await fulfillment(of: [adasExpectation], timeout: defaultDelay)

        // assert
        guard let adasAttributes else {
            XCTFail("Adas Attributes should not be nil")
            return
        }
        let speedLimits = [
            RoadGraph.Edge.SpeedLimitInfo(
                speedLimit: .init(value: 100.0, unit: .kilometersPerHour),
                kind: .explicit,
                restriction: .init(weather: [.wetRoad], timeCondition: "", vehicleTypes: [], lanes: [])
            ),
            RoadGraph.Edge.SpeedLimitInfo(
                speedLimit: .init(value: 255.0, unit: .kilometersPerHour),
                kind: .implicit,
                restriction: .init(weather: [], timeCondition: "", vehicleTypes: [], lanes: [])
            ),
        ]

        XCTAssertNil(adasAttributes.isBuiltUpArea, "isBuiltUpArea should be unknown")
        XCTAssertEqual(adasAttributes.isDividedRoad, true, "isDividedRoad should be 'true'")
        XCTAssertEqual(adasAttributes.formOfWay, .freeway, "formOfWay should be 'freeway'")
        XCTAssertTrue(adasAttributes.curvatures.isEmpty, "curvatures should be empty")
        XCTAssertTrue(adasAttributes.roadItems.isEmpty, "roadItems should be empty")
        XCTAssertEqual(adasAttributes.speedLimit, speedLimits, "SpeedLimits are not correct")
        XCTAssertEqual(adasAttributes.slopes.count, 16, "Number of slopes is not correct")
        XCTAssertEqual(
            adasAttributes.slopes.first,
            .init(
                position: .init(
                    edgeIdentifier: 6453960139032,
                    fractionFromStart: 0.0006070188754218256
                ),
                edgeShapeIndex: 0.5600000023841858,
                value: -0.10949931456485504
            ),
            "The first slope is not correct"
        )
        XCTAssertEqual(adasAttributes.elevations.count, 17, "Number of elevations is not correct")
        XCTAssertEqual(
            adasAttributes.elevations.first,
            .init(
                position: .init(
                    edgeIdentifier: 6453960139032,
                    fractionFromStart: 0.0
                ),
                edgeShapeIndex: 0.0,
                value: 458.36
            ),
            "The first elevation is not correct"
        )
    }
}
