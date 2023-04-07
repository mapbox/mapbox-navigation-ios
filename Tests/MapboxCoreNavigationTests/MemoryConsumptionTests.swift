import XCTest
import TestHelper
import MapboxCoreNavigation
import CoreLocation
import MapboxDirections
import MapboxNavigationNative
import MapboxCommon

@available(iOS 13.0, *)
final class MemoryConsumptionTests: TestCase {
    let jsonFileName = "long_routes"
    let routeOptions = NavigationRouteOptions(coordinates: [
        CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0),
        CLLocationCoordinate2D(latitude: 1.0, longitude: 1.0)
    ])
        
    func testRouteParserFromString() {
        let jsonData = Fixture.JSONFromFileNamed(name: jsonFileName)
        let url = Directions.mocked.url(forCalculating: routeOptions).absoluteString
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            XCTFail()
            return
        }
        
        measure(metrics: [XCTClockMetric(), XCTMemoryMetric(), XCTCPUMetric()]) {
            let routes = RouteParser.parseDirectionsResponse(forResponse: jsonString,
                                                             request: url,
                                                             routeOrigin: .custom)
        }
    }
    
    func testGetRequestFromString() {
        let jsonData = Fixture.JSONFromFileNamed(name: jsonFileName)
        let url = Directions.mocked.url(forCalculating: routeOptions).absoluteString
        guard let jsonString = String(data: jsonData, encoding: .utf8) else {
            XCTFail()
            return
        }
        guard let routes = RouteParser.parseDirectionsResponse(forResponse: jsonString,
                                                               request: url,
                                                               routeOrigin: .custom).value as? [RouteInterface],
              let routeInterface = routes.first else {
            XCTFail()
            return
        }

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric(), XCTCPUMetric()]) {
            _ = StringCoding.decode(routeRequest: routeInterface.getRequestUri(),
                                    routeResponse: routeInterface.getResponseJson())
        }
    }
    
    func testRouteParserFromData() {
        let jsonData = Fixture.JSONFromFileNamed(name: jsonFileName)
        let url = Directions.mocked.url(forCalculating: routeOptions).absoluteString

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric(), XCTCPUMetric()]) {
            _ = RouteParser.parseDirectionsResponse(forResponseDataRef: DataRef(data: jsonData),
                                                             request: url,
                                                             routeOrigin: .custom)
        }
    }
    
    func testGetRequestFromData() {
        let jsonData = Fixture.JSONFromFileNamed(name: jsonFileName)
        let url = Directions.mocked.url(forCalculating: routeOptions).absoluteString
        
        guard let routes = RouteParser.parseDirectionsResponse(forResponseDataRef: DataRef(data: jsonData),
                                                               request: url,
                                                               routeOrigin: .custom).value as? [RouteInterface],
              let routeInterface = routes.first else {
            XCTFail()
            return
        }

        measure(metrics: [XCTClockMetric(), XCTMemoryMetric(), XCTCPUMetric()]) {
            routeInterface.getResponseJsonRef().withData{ data in
                _ = DataCoding.decode(routeRequest: routeInterface.getRequestUri(),
                                      routeResponse: data)
            }
        }
    }
}

enum StringCoding {
    static internal func decode(routeRequest: String, routeResponse: String) -> (routeOptions: RouteOptions, routeResponse: RouteResponse)? {
        guard let decodedRequest = decode(routeRequest: routeRequest),
              let decodedResponse = decode(routeResponse: routeResponse,
                                           routeOptions: decodedRequest.routeOptions,
                                           credentials: decodedRequest.credentials) else {
            return nil
        }

        return (decodedRequest.routeOptions, decodedResponse)
    }

    static internal func decode(routeRequest: String) -> (routeOptions: RouteOptions, credentials: Credentials)? {
        guard let requestURL = URL(string: routeRequest),
              let routeOptions = RouteOptions(url: requestURL) else {
                  return nil
        }

        return (routeOptions: routeOptions,
                credentials: Credentials(requestURL: requestURL))
    }

    static internal func decode(routeResponse: String,
                                routeOptions: RouteOptions,
                                credentials: Credentials) -> RouteResponse? {
        guard let data = routeResponse.data(using: .utf8) else {
            return nil
        }

        let decoder = JSONDecoder()
        decoder.userInfo[.options] = routeOptions
        decoder.userInfo[.credentials] = credentials

        return try? decoder.decode(RouteResponse.self,
                                   from: data)
    }
}

enum DataCoding {
    static internal func decode(routeRequest: String, routeResponse: Data) -> (routeOptions: RouteOptions, routeResponse: RouteResponse)? {
        guard let decodedRequest = decode(routeRequest: routeRequest),
              let decodedResponse = decode(routeResponse: routeResponse,
                                           routeOptions: decodedRequest.routeOptions,
                                           credentials: decodedRequest.credentials) else {
            return nil
        }

        return (decodedRequest.routeOptions, decodedResponse)
    }

    static internal func decode(routeRequest: String) -> (routeOptions: RouteOptions, credentials: Credentials)? {
        guard //let requestURL = URL(dataRepresentation: routeRequest, relativeTo: nil),
            let requestURL = URL(string: routeRequest),
              let routeOptions = RouteOptions(url: requestURL) else {
                  return nil
        }

        return (routeOptions: routeOptions,
                credentials: Credentials(requestURL: requestURL))
    }

    static internal func decode(routeResponse: Data,
                                routeOptions: RouteOptions,
                                credentials: Credentials) -> RouteResponse? {
//        guard let data = routeResponse.data(using: .utf8) else {
//            return nil
//        }

        let decoder = JSONDecoder()
        decoder.userInfo[.options] = routeOptions
        decoder.userInfo[.credentials] = credentials

        return try? decoder.decode(RouteResponse.self,
                                   from: routeResponse)
    }
}
