import XCTest
#if !os(Linux)
import CoreLocation
import OHHTTPStubs
#if SWIFT_PACKAGE
import OHHTTPStubsSwift
#endif
@testable import MapboxDirections
import Turf

class OfflineDirectionsTests: XCTestCase {
    let token = "foo"
    let host = "api.mapbox.com"
    let hostURL = URL(string: "https://api.mapbox.com")!

    func testAvailableVersions() {
        let credentials = Credentials(accessToken: token, host: hostURL)
        let directions = Directions(credentials: credentials)

        let versionsExpectation = expectation(description: "Fetching available versions should return results")

        let apiStub = stub(condition: isHost(host)) { _ in
            let bundle = Bundle.module
            let path = bundle.path(forResource: "versions", ofType: "json")
            let filePath = URL(fileURLWithPath: path!)
            let data = try! Data(contentsOf: filePath)
            let jsonObject = try! JSONSerialization.jsonObject(with: data, options: [])
            return HTTPStubsResponse(
                jsonObject: jsonObject,
                statusCode: 200,
                headers: ["Content-Type": "application/json"]
            )
        }

        directions.fetchAvailableOfflineVersions { versions, _ in
            XCTAssertEqual(versions!.count, 1)
            XCTAssertEqual(versions!.first!, "2018-10-16")

            versionsExpectation.fulfill()
            HTTPStubs.removeStub(apiStub)
        }

        wait(for: [versionsExpectation], timeout: 2)
    }

    func testDownloadTiles() {
        let directions = Directions(credentials: BogusCredentials)
        let bounds = BoundingBox(
            southWest: CLLocationCoordinate2D(latitude: 37.7890, longitude: -122.4337),
            northEast: CLLocationCoordinate2D(latitude: 37.7881, longitude: -122.4318)
        )

        let version = "2018-10-16"
        let downloadExpectation = expectation(description: "Download tile expectation")

        let apiStub = stub(condition: isHost(host)) { _ in
            let bundle = Bundle.module
            let path = bundle.path(forResource: "2018-10-16-Liechtenstein", ofType: "tar")

            let attributes = try! FileManager.default.attributesOfItem(atPath: path!)
            let fileSize = attributes[.size] as! UInt64

            var headers = [AnyHashable: Any]()
            headers["Content-Type"] = "application/gzip"
            headers["Content-Length"] = "\(fileSize)"
            headers["Accept-Ranges"] = "bytes"
            headers["Content-Disposition"] = "attachment; filename=\"\(version).tar\""

            return HTTPStubsResponse(fileAtPath: path!, statusCode: 200, headers: headers)
        }

        directions.downloadTiles(in: bounds, version: version, completionHandler: { url, response, error in
            XCTAssertEqual(response!.suggestedFilename, "2018-10-16.tar")
            XCTAssertNotNil(url, "url should point to the temporary local file")
            XCTAssertNil(error)

            downloadExpectation.fulfill()
            HTTPStubs.removeStub(apiStub)
        })

        wait(for: [downloadExpectation], timeout: 60)
    }
}
#endif
