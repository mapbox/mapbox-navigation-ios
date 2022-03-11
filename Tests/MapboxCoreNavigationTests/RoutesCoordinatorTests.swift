import Foundation
import XCTest
import TestHelper
import MapboxNavigationNative
@testable import MapboxCoreNavigation

final class RoutesCoordinatorTests: TestCase {
    func testNormalCase() {
        let uuid = UUID()
        runTestCases([
            .init(routes: generateRoutes(), uuid: uuid, routeIndex: 0, expectedResult: .success(())),
            .init(routes: nil, uuid: uuid, routeIndex: 0, expectedResult: .success(()))
        ])
    }

    func testEndingOverriddenNavigation() {
        let uuid1 = UUID()
        let uuid2 = UUID()
        runTestCases([
            .init(routes: generateRoutes(), uuid: uuid1, routeIndex: 0, expectedResult: .success(())),
            .init(routes: generateRoutes(), uuid: uuid2, routeIndex: 0, expectedResult: .success(())),
            .init(routes: nil, uuid: uuid1, routeIndex: 0, expectedResult: .failure(.endingInvalidActiveNavigation)),
        ])
    }

    func testReroutes() {
        let uuid = UUID()
        runTestCases([
            .init(routes: generateRoutes(), uuid: uuid, routeIndex: 0, expectedResult: .success(())),
            .init(routes: generateRoutes(), uuid: uuid, routeIndex: 0, expectedResult: .success(())),
            .init(routes: nil, uuid: uuid, routeIndex: 0, expectedResult: .success(())),
        ])
    }
}

private extension RoutesCoordinatorTests {
    func generateRoutes() -> NavigationRoutes {
        .init(primaryRouteId: UUID().uuidString, routes: [])
    }

    struct RoutesCoordinatorTestCase {
        let routes: NavigationRoutes?
        let uuid: UUID
        let routeIndex: UInt32
        let expectedResult: Result<Void, RoutesCoordinatorError>

    }

    func runTestCases(_ testCases: [RoutesCoordinatorTestCase]) {
        var expectedRoutes: NavigationRoutes? = generateRoutes()
        var expectedRouteIndex = UInt32.max
        var expectedResult: Result<RouteInfo, RoutesCoordinatorError>!

        let handler: RoutesCoordinator.SetRoutesHandler = { routes, routeIndex, completion in
            XCTAssertEqual(routes, expectedRoutes)
            XCTAssertEqual(routeIndex, expectedRouteIndex)
            completion(expectedResult.mapError { $0 as Error })
        }

        let coordinator = RoutesCoordinator { routes, routeIndex, completion in
            handler(routes, routeIndex, completion)
        }

        for testCase in testCases {
            let expectation = expectation(description: "Test case finished")
            if let routes = testCase.routes {
                expectedResult = testCase.expectedResult
                    .map { .init(alerts: []) }
                expectedRoutes = routes
                expectedRouteIndex = testCase.routeIndex
                coordinator.beginActiveNavigation(with: routes, uuid: testCase.uuid, legIndex: testCase.routeIndex) { result in
                    switch (result, expectedResult) {
                    case (.success(let routeInfo), .success(let expectedRouteInfo)):
                        XCTAssertEqual(routeInfo, expectedRouteInfo)
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
                    .map { .init(alerts: []) }
                expectedRoutes = nil
                coordinator.endActiveNavigation(with: testCase.uuid) { result in
                    switch (result, expectedResult) {
                    case (.success(let routeInfo), .success(let expectedRouteInfo)):
                        XCTAssertEqual(routeInfo, expectedRouteInfo)
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
