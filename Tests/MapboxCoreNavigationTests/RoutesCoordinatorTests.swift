import Foundation
import XCTest
import TestHelper
import MapboxNavigationNative
import MapboxDirections
@testable import MapboxCoreNavigation
@_implementationOnly import MapboxCommon_Private
@_implementationOnly import MapboxNavigationNative_Private

final class RoutesCoordinatorTests: TestCase {
    func testNormalCase() {
        let uuid = UUID()
        runTestCases([
            .init(routes: createRoutes(), uuid: uuid, legIndex: 0, reason: .startNewRoute, expectedResult: .success(())),
            .init(routes: createRoutes(), uuid: uuid, legIndex: 0, reason: .reroute, expectedResult: .success(())),
            .init(routes: createRoutes(), uuid: uuid, legIndex: 0, reason: .switchToOnline, expectedResult: .success(())),
            .init(routes: createRoutes(), uuid: uuid, legIndex: 0, reason: .fallbackToOffline, expectedResult: .success(())),
            .init(routes: nil, uuid: uuid, legIndex: 0, reason: .cleanUp, expectedResult: .success(()))
        ])
    }

    func testEndingOverriddenNavigation() {
        let uuid1 = UUID()
        let uuid2 = UUID()
        runTestCases([
            .init(routes: createRoutes(), uuid: uuid1, legIndex: 0, reason: .startNewRoute, expectedResult: .success(())),
            .init(routes: createRoutes(), uuid: uuid2, legIndex: 0, reason: .startNewRoute, expectedResult: .success(())),
            .init(routes: nil, uuid: uuid1, legIndex: 0, reason: .cleanUp, expectedResult: .failure(.endingInvalidActiveNavigation)),
        ])
    }

    func testReroutes() {
        let uuid = UUID()
        runTestCases([
            .init(routes: createRoutes(), uuid: uuid, legIndex: 0, reason: .startNewRoute, expectedResult: .success(())),
            .init(routes: createRoutes(), uuid: uuid, legIndex: 0, reason: .startNewRoute, expectedResult: .success(())),
            .init(routes: nil, uuid: uuid, legIndex: 0, reason: .cleanUp, expectedResult: .success(())),
        ])
    }
}

private extension RoutesCoordinatorTests {
    func createRoutes() -> RouteInterface? {
        return TestRouteProvider.createRoute()
    }

    struct RoutesCoordinatorTestCase {
        let routes: RouteInterface?
        let uuid: UUID
        let legIndex: UInt32
        let reason: RouteChangeReason
        let expectedResult: Result<Void, RoutesCoordinatorError>

    }

    func runTestCases(_ testCases: [RoutesCoordinatorTestCase]) {
        var expectedRoutes: RouteInterface? = createRoutes()
        var expectedLegIndex = UInt32.max
        var expectedResult: Result<RoutesCoordinator.RoutesResult, RoutesCoordinatorError>!
        var expectedReason: RouteChangeReason = .startNewRoute

        let handler: RoutesCoordinator.RoutesSetupHandler = { routesData, legIndex, reason, completion in
            XCTAssertEqual(routesData?.primaryRoute().getRouteId(), expectedRoutes?.getRouteId())
            XCTAssertEqual(legIndex, expectedLegIndex)
            XCTAssertEqual(reason, expectedReason)
            XCTAssertTrue(routesData?.alternativeRoutes().isEmpty ?? true)
            completion(expectedResult.mapError { $0 as Error })
        }

        let coordinator = RoutesCoordinator(routesSetupHandler: { routesData, routeIndex, reason, completion in
            handler(routesData, routeIndex, reason, completion)
        }, alternativeRoutesSetupHandler: { _, _ in })

        for testCase in testCases {
            let expectation = expectation(description: "Test case finished")
            expectedReason = testCase.reason
            if let routes = testCase.routes {
                expectedResult = testCase.expectedResult
                    .map { (.init(alerts: []), []) }
                expectedRoutes = routes
                expectedLegIndex = testCase.legIndex
                let routesData = RouteParser.createRoutesData(forPrimaryRoute: routes,
                                                              alternativeRoutes: [])
                coordinator.beginActiveNavigation(with: routesData,
                                                  uuid: testCase.uuid,
                                                  legIndex: testCase.legIndex,
                                                  reason: testCase.reason) { result in
                    switch (result, expectedResult) {
                    case (.success(let routeInfo), .success(let expectedRouteInfo)):
                        XCTAssertEqual(routeInfo.0, expectedRouteInfo.0)
                        XCTAssertEqual(routeInfo.1, expectedRouteInfo.1)
                    case (.failure(let error), .failure(let expectedError)):
                        XCTAssertEqual(error as? RoutesCoordinatorError, expectedError)
                    default:
                        XCTFail("Invalid result: \(result)")
                    }
                    expectation.fulfill()
                }
            } else {
                expectedResult = testCase.expectedResult
                    .map { (.init(alerts: []), []) }
                expectedRoutes = nil
                coordinator.endActiveNavigation(with: testCase.uuid) { result in
                    switch (result, expectedResult) {
                    case (.success(let routeInfo), .success(let expectedRouteInfo)):
                        XCTAssertEqual(routeInfo.0, expectedRouteInfo.0)
                        XCTAssertEqual(routeInfo.1, expectedRouteInfo.1)
                    case (.failure(let error), .failure(let expectedError)):
                        XCTAssertEqual(error as? RoutesCoordinatorError, expectedError)
                    default:
                        XCTFail("Invalid result: \(result)")
                    }
                    expectation.fulfill()
                }
            }
            wait(for: [expectation], timeout: 1)
        }
    }
}
