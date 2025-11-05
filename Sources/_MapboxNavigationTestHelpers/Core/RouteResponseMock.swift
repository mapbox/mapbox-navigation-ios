import MapboxDirections
import XCTest

extension RouteResponse {
    static func mock(bundle: Bundle, options: RouteOptions, fileName: String) -> RouteResponse? {
        makeResponse(bundle: bundle, options: options, fileName: fileName)
    }
}

extension MapMatchingResponse {
    static func mock(
        bundle: Bundle,
        options: MatchOptions,
        fileName: String
    ) -> MapMatchingResponse? {
        makeResponse(bundle: bundle, options: options, fileName: fileName)
    }
}

func responseJsonData(
    bundle: Bundle,
    fileName: String
) -> Data? {
    guard let fixtureURL = bundle.url(
        forResource: fileName,
        withExtension: "json",
        subdirectory: "Fixtures"
    ) else {
        XCTFail("File not found")
        return nil
    }
    return try? Data(contentsOf: fixtureURL)
}

func makeResponse<ResponseType: Codable>(
    bundle: Bundle,
    options: DirectionsOptions,
    fileName: String
) -> ResponseType? {
    guard let responseData = responseJsonData(bundle: bundle, fileName: fileName) else {
        XCTFail("File cannot be read")
        return nil
    }
    do {
        let decoder = JSONDecoder()
        decoder.userInfo[.options] = options
        decoder.userInfo[.credentials] = Credentials.mock()
        return try decoder.decode(ResponseType.self, from: responseData)
    } catch {
        XCTFail("File cannot be decoded, error: \(error)")
        return nil
    }
}
