import _MapboxNavigationHelpers
import MapboxDirections
@testable import MapboxNavigationUIKit
import XCTest

final class MapboxApiEndpointTests: XCTestCase {
    func testIsMapboxApiEndpointMatchesSchemeAndHost() throws {
        let mapboxURLs = [
            "https://api.mapbox.com",
            "https://api.mapbox.com/guidance-views/v1/x?arrow_ids=A",
            "https://API.MAPBOX.COM/guidance-views/v1/x",
            "HTTPS://api.mapbox.com/guidance-views/v1/x",
        ]
        for rawURL in mapboxURLs {
            XCTAssertTrue(try XCTUnwrap(URL(string: rawURL)).isMapboxApiEndpoint, rawURL)
        }

        let otherURLs = [
            "https://attacker.example/x?a=b",
            "https://api.mapbox.com.attacker.example/x",
            "https://api.mapbox.com@attacker.example/x",
            "http://api.mapbox.com/guidance-views/v1/x",
            "https://api.mapbox.com./guidance-views/v1/x",
            "https://not-mapbox.com/path?redirect=https://api.mapbox.com",
            "/guidance-views/v1/x",
        ]
        for rawURL in otherURLs {
            XCTAssertFalse(try XCTUnwrap(URL(string: rawURL)).isMapboxApiEndpoint, rawURL)
        }
    }

    func testAddingMapboxAccessTokenPreservesExistingQuery() throws {
        let imageURL = try XCTUnwrap(
            URL(string: "https://api.mapbox.com/guidance-views/v1/1/jct/JV?arrow_ids=JV1")
        )

        let authenticatedURL = imageURL.addingMapboxAccessToken("pk.victim")

        XCTAssertEqual(
            authenticatedURL.absoluteString,
            "https://api.mapbox.com/guidance-views/v1/1/jct/JV?arrow_ids=JV1&access_token=pk.victim"
        )
    }

    func testAddingMapboxAccessTokenAddsQueryWhenURLHasNone() throws {
        let imageURL = try XCTUnwrap(URL(string: "https://api.mapbox.com/guidance-views/v1/x"))

        XCTAssertEqual(
            imageURL.addingMapboxAccessToken("pk.victim").absoluteString,
            "https://api.mapbox.com/guidance-views/v1/x?access_token=pk.victim"
        )
    }

    func testAddingMapboxAccessTokenReplacesExistingAccessToken() throws {
        let imageURL = try XCTUnwrap(
            URL(string: "https://api.mapbox.com/guidance-views/v1/x?access_token=stolen&arrow_ids=1")
        )

        XCTAssertEqual(
            imageURL.addingMapboxAccessToken("pk.victim").absoluteString,
            "https://api.mapbox.com/guidance-views/v1/x?arrow_ids=1&access_token=pk.victim"
        )
    }

    func testAddingMapboxAccessTokenPreservesExistingQueryEncoding() throws {
        let imageURL = try XCTUnwrap(
            URL(string: "https://api.mapbox.com/guidance-views/v1/x?a=b%2Fc&d=e+f&g=%2B&flag")
        )

        XCTAssertEqual(
            imageURL.addingMapboxAccessToken("pk.victim").absoluteString,
            "https://api.mapbox.com/guidance-views/v1/x?a=b%2Fc&d=e+f&g=%2B&flag&access_token=pk.victim"
        )
    }

    func testAddingMapboxAccessTokenEncodesReservedCharactersInToken() throws {
        let imageURL = try XCTUnwrap(URL(string: "https://api.mapbox.com/guidance-views/v1/x?arrow_ids=A"))

        let authenticatedURL = imageURL.addingMapboxAccessToken("pk.a&b=c+d")

        XCTAssertEqual(queryItems(in: authenticatedURL), [
            URLQueryItem(name: "arrow_ids", value: "A"),
            URLQueryItem(name: "access_token", value: "pk.a&b=c+d"),
        ])
    }

    func testAddingMapboxAccessTokenLeavesURLUnchangedWhenTokenIsEmpty() throws {
        let imageURL = try XCTUnwrap(URL(string: "https://api.mapbox.com/guidance-views/v1/x"))

        XCTAssertEqual(imageURL.addingMapboxAccessToken(""), imageURL)
    }

    func testAddingMapboxAccessTokenLeavesOtherURLsUnchanged() throws {
        let otherURLs = [
            "https://attacker.example/x?a=b",
            "https://attacker.example/x?access_token=already-there",
            "https://api.mapbox.com.attacker.example/x",
            "https://api.mapbox.com@attacker.example/x",
            "http://api.mapbox.com/guidance-views/v1/x",
            "https://api.mapbox.com./guidance-views/v1/x",
        ]

        for rawURL in otherURLs {
            let imageURL = try XCTUnwrap(URL(string: rawURL))
            let authenticatedURL = imageURL.addingMapboxAccessToken("pk.victim")
            XCTAssertEqual(authenticatedURL, imageURL, rawURL)
            XCTAssertFalse(authenticatedURL.absoluteString.contains("pk.victim"), rawURL)
        }
    }

    func testJunctionViewRequestsForeignHostWithoutToken() throws {
        let downloader = RecordingImageDownloader()
        let junctionView = JunctionView(frame: .zero)
        junctionView.imageRepository = ImageRepository(withDownloader: downloader, useDisk: false)
        let imageURL = try XCTUnwrap(URL(string: "https://attacker.example/x?a=b"))

        junctionView.update(for: banner(imageURL: imageURL), accessToken: "pk.victim")

        XCTAssertEqual(downloader.requestedURLs, [imageURL])
    }

    func testJunctionViewRequestsMapboxHostWithToken() throws {
        let downloader = RecordingImageDownloader()
        let junctionView = JunctionView(frame: .zero)
        junctionView.imageRepository = ImageRepository(withDownloader: downloader, useDisk: false)
        let imageURL = try XCTUnwrap(
            URL(string: "https://api.mapbox.com/guidance-views/v1/1/jct/JV?arrow_ids=A")
        )

        junctionView.update(for: banner(imageURL: imageURL), accessToken: "pk.victim")

        XCTAssertEqual(downloader.requestedURLs.map(\.absoluteString), [
            "https://api.mapbox.com/guidance-views/v1/1/jct/JV?arrow_ids=A&access_token=pk.victim",
        ])
    }

    func testJunctionViewSkipsRequestWithoutToken() throws {
        let downloader = RecordingImageDownloader()
        let junctionView = JunctionView(frame: .zero)
        junctionView.imageRepository = ImageRepository(withDownloader: downloader, useDisk: false)
        let imageURL = try XCTUnwrap(URL(string: "https://api.mapbox.com/guidance-views/v1/1/jct/JV?arrow_ids=A"))

        junctionView.update(for: banner(imageURL: imageURL), accessToken: nil)

        XCTAssertTrue(downloader.requestedURLs.isEmpty)
    }

    private func queryItems(in url: URL) -> [URLQueryItem]? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
    }

    private func banner(imageURL: URL) -> VisualInstructionBanner {
        let primary = VisualInstruction(
            text: "Continue",
            maneuverType: .turn,
            maneuverDirection: .right,
            components: [
                .text(text: .init(text: "Continue", abbreviation: nil, abbreviationPriority: nil)),
            ]
        )
        let guidanceView = VisualInstruction.Component.guidanceView(
            image: GuidanceViewImageRepresentation(imageURL: imageURL),
            alternativeText: .init(text: "junction", abbreviation: nil, abbreviationPriority: nil)
        )
        let quaternary = VisualInstruction(
            text: "junction",
            maneuverType: .reachFork,
            maneuverDirection: .right,
            components: [guidanceView]
        )
        return VisualInstructionBanner(
            distanceAlongStep: 100,
            primary: primary,
            secondary: nil,
            tertiary: nil,
            quaternary: quaternary,
            drivingSide: .right
        )
    }
}

private final class RecordingImageDownloader: ImageDownloaderProtocol {
    private(set) var requestedURLs: [URL] = []

    func download(with url: URL, completion: @escaping (Result<CachedURLResponse, Error>) -> Void) {
        requestedURLs.append(url)
    }
}
