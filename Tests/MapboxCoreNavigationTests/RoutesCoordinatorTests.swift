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
        guard let routeData = try? encoder.encode(route.response),
              let routeJSONString = String(data: routeData, encoding: .utf8) else {
                  XCTFail("Failed to encode generated test Route.")
                  return nil
        }
        let routeRequest = Directions(credentials: Fixture.credentials).url(forCalculating: routeOptions).absoluteString
        
        let parsedRoutes = RouteParser.parseDirectionsResponse(forResponse: routeJSONString,
                                                               request: routeRequest,
                                                               routeOrigin: RouterOrigin.custom)
        var generatedRoute: RouteInterface? = nil
        if parsedRoutes.isValue(),
           let validGeneratedRoute = (parsedRoutes.value as? [RouteInterface])?.first {
            generatedRoute = validGeneratedRoute
        } else if parsedRoutes.isError(),
                  let errorReason = parsedRoutes.error as String? {
            XCTFail("Failed to parse generated test route with error: \(errorReason).")
        } else {
            XCTFail("Failed to parse generated test route.")
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
        var expectedResult: Result<RoutesCoordinator.RoutesResult, RoutesCoordinatorError>!

        let handler: RoutesCoordinator.RoutesSetupHandler = { routes, routeIndex, alternativeRoutes, completion in
            XCTAssertEqual(routes?.getRouteId(), expectedRoutes?.getRouteId())
            XCTAssertEqual(routeIndex, expectedRouteIndex)
            XCTAssertTrue(alternativeRoutes.isEmpty)
            completion(expectedResult.mapError { $0 as Error })
        }

        let coordinator = RoutesCoordinator(routesSetupHandler: { route, routeIndex, alternativeRoutes, completion in
            handler(route, routeIndex, alternativeRoutes, completion)
        }, alternativeRoutesSetupHandler: { _, _ in })

        for testCase in testCases {
            let expectation = expectation(description: "Test case finished")
            if let routes = testCase.routes {
                expectedResult = testCase.expectedResult
                    .map { (.init(alerts: []), []) }
                expectedRoutes = routes
                expectedRouteIndex = testCase.routeIndex
                coordinator.beginActiveNavigation(with: routes, uuid: testCase.uuid, legIndex: testCase.routeIndex, alternativeRoutes: []) { result in
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
