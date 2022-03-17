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
    func generateRoutes() -> RouteInterface? {
        let route = Fixture.route(between: .init(latitude: 0, longitude: 0),
                                  and: .init(latitude: 1, longitude: 1))
        guard case let .route(routeOptions) = route.response.options else {
            XCTFail("Failed to generate test Route.")
            return nil
        }
        let encoder = JSONEncoder()
        encoder.userInfo[.options] = routeOptions
        guard let routeData = try? encoder.encode(route.route),
              let routeJSONString = String(data: routeData, encoding: .utf8) else {
                  XCTFail("Failed to encode generated test Route.")
                  return nil
        }
        
        let routeRequest = Directions(credentials: Fixture.credentials).url(forCalculating: routeOptions).absoluteString
        
        let parsedRoutes = RouteParser.parseDirectionsResponse(forResponse: routeJSONString,
                                                               request: routeRequest)
        
        guard let generatedRoute = (parsedRoutes.value as? [RouteInterface])?.first else {
            XCTFail("Failed to parse generated test Route.")
            return nil
        }
        return generatedRoute
    }

    struct RoutesCoordinatorTestCase {
        let routes: RouteInterface?
        let uuid: UUID
        let routeIndex: UInt32
        let expectedResult: Result<Void, RoutesCoordinatorError>

    }

    func runTestCases(_ testCases: [RoutesCoordinatorTestCase]) {
        var expectedRoutes: RouteInterface? = generateRoutes()
        var expectedRouteIndex = UInt32.max
        var expectedResult: Result<RouteInfo, RoutesCoordinatorError>!

        let handler: RoutesCoordinator.SetRoutesHandler = { routes, routeIndex, completion in
            XCTAssertEqual(routes?.getRouteId(), expectedRoutes?.getRouteId())
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
