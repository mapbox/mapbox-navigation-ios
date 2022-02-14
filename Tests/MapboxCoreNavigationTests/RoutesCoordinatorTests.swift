import Foundation
import XCTest
import TestHelper
import MapboxNavigationNative
@testable import MapboxCoreNavigation

final class RoutesCoordinatorTests: TestCase {
    func testNormalCase() {
        let uuid = UUID()
        runTestCases([
            .init(routes: generateRoutes(), uuid: uuid, expectedResult: .success(())),
            .init(routes: nil, uuid: uuid, expectedResult: .success(()))
        ])
    }

    func testEndingOverriddenNavigation() {
        let uuid1 = UUID()
        let uuid2 = UUID()
        runTestCases([
            .init(routes: generateRoutes(), uuid: uuid1, expectedResult: .success(())),
            .init(routes: generateRoutes(), uuid: uuid2, expectedResult: .success(())),
            .init(routes: nil, uuid: uuid1, expectedResult: .failure(.endingInvalidActiveNavigation)),
        ])
    }

    func testReroutes() {
        let uuid = UUID()
        runTestCases([
            .init(routes: generateRoutes(), uuid: uuid, expectedResult: .success(())),
            .init(routes: generateRoutes(), uuid: uuid, expectedResult: .success(())),
            .init(routes: nil, uuid: uuid, expectedResult: .success(())),
        ])
    }
}

private extension RoutesCoordinatorTests {
    func generateRoutes() -> Routes {
        .init(routesResponse: UUID().uuidString, routeIndex: 0, legIndex: 0, routesRequest: "")
    }

    struct RoutesCoordinatorTestCase {
        let routes: Routes?
        let uuid: UUID
        let expectedResult: Result<Void, RoutesCoordinatorError>

    }

    func runTestCases(_ testCases: [RoutesCoordinatorTestCase]) {
        var expectedRoutes: Routes? = generateRoutes()
        var expectedResult: Result<RouteInfo, RoutesCoordinatorError>!

        let handler: RoutesCoordinator.SetRoutesHandler = { routes, completion in
            XCTAssertEqual(routes, expectedRoutes)
            completion(expectedResult.mapError { $0 as Error })
        }

        let coordinator = RoutesCoordinator { routes, completion in
            handler(routes, completion)
        }

        for testCase in testCases {
            let expectation = expectation(description: "Test case finished")
            if let routes = testCase.routes {
                expectedResult = testCase.expectedResult
                    .map { .init(alerts: []) }
                expectedRoutes = routes
                coordinator.beginActiveNavigation(with: routes, uuid: testCase.uuid) { result in
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
