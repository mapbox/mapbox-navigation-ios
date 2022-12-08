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
            .init(routes: createRoutes(), uuid: uuid, legIndex: 0, expectedResult: .success(())),
            .init(routes: nil, uuid: uuid, legIndex: 0, expectedResult: .success(()))
        ])
    }

    func testEndingOverriddenNavigation() {
        let uuid1 = UUID()
        let uuid2 = UUID()
        runTestCases([
            .init(routes: createRoutes(), uuid: uuid1, legIndex: 0, expectedResult: .success(())),
            .init(routes: createRoutes(), uuid: uuid2, legIndex: 0, expectedResult: .success(())),
            .init(routes: nil, uuid: uuid1, legIndex: 0, expectedResult: .failure(.endingInvalidActiveNavigation)),
        ])
    }

    func testReroutes() {
        let uuid = UUID()
        runTestCases([
            .init(routes: createRoutes(), uuid: uuid, legIndex: 0, expectedResult: .success(())),
            .init(routes: createRoutes(), uuid: uuid, legIndex: 0, expectedResult: .success(())),
            .init(routes: nil, uuid: uuid, legIndex: 0, expectedResult: .success(())),
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
        let expectedResult: Result<Void, RoutesCoordinatorError>

    }

    func runTestCases(_ testCases: [RoutesCoordinatorTestCase]) {
        var expectedRoutes: RouteInterface? = createRoutes()
        var expectedLegIndex = UInt32.max
        var expectedResult: Result<RoutesCoordinator.RoutesResult, RoutesCoordinatorError>!

        let handler: RoutesCoordinator.RoutesSetupHandler = { routesData, legIndex, completion in
            XCTAssertEqual(routesData?.primaryRoute().getRouteId(), expectedRoutes?.getRouteId())
            XCTAssertEqual(legIndex, expectedLegIndex)
            XCTAssertTrue(routesData?.alternativeRoutes().isEmpty ?? true)
            completion(expectedResult.mapError { $0 as Error })
        }

        let coordinator = RoutesCoordinator(routesSetupHandler: { routesData, routeIndex, completion in
            handler(routesData, routeIndex, completion)
        }, alternativeRoutesSetupHandler: { _, _ in })

        for testCase in testCases {
            let expectation = expectation(description: "Test case finished")
            if let routes = testCase.routes {
                expectedResult = testCase.expectedResult
                    .map { (.init(alerts: []), []) }
                expectedRoutes = routes
                expectedLegIndex = testCase.legIndex
                let routesData = RouteParser.createRoutesData(forPrimaryRoute: routes,
                                                              alternativeRoutes: [])
                coordinator.beginActiveNavigation(with: routesData, uuid: testCase.uuid, legIndex: testCase.legIndex) { result in
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
            else {
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
