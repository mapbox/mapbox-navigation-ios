@_spi(Internal) import MapboxMaps
import XCTest

open class BaseTestCase: XCTestCase {
    override open func setUpWithError() throws {
        try super.setUpWithError()
        Self.injectSharedToken()
        Self.resolveDefaultStylesOffline()
    }

    override open func setUp() async throws {
        try? await super.setUp()
        Self.injectSharedToken()
        Self.resolveDefaultStylesOffline()
    }

    override open func tearDownWithError() throws {
        Self.clearInjectSharedToken()
        Self.restoreDefaultStyles()
    }

    public static func injectSharedToken(_ accessToken: String = .mockedAccessToken) {
        MapboxOptions.accessToken = .mockedAccessToken
        UserDefaults.standard.set(accessToken, forKey: "MBXAccessToken")
    }

    public static func clearInjectSharedToken() {
        MapboxOptions.accessToken = ""
        UserDefaults.standard.removeObject(forKey: "MBXAccessToken")
    }

    /// Resolve the styles a `MapView` loads by default to an empty local style, so no style
    /// request is ever issued.
    /// Only styles loaded *implicitly*, as somebody's default, belong in this list. The
    /// replacement is JSON-backed, so `mapboxMap.styleURI` reads back `nil` and a tileset
    /// descriptor can no longer be derived: add a style a test sets and then asserts on and
    /// you break that test.
    /// A test wanting real style content sets it explicitly; `MapStyle(json:)` and file
    /// URIs both bypass this map.
    ///
    /// `TestHelper.TestCase` carries the same list for the test targets built against it.
    public static func resolveDefaultStylesOffline() {
        let implicitlyLoadedStyleURIs: [StyleURI] = [
            .standard,
            .standardSatellite,
            // MapboxNavigationUIKit's navigationMapStyleUrl and its satellite counterpart,
            // by raw value so this stays character-identical to the other copy.
            StyleURI(rawValue: "mapbox://styles/mapbox-dash/standard-navigation")!,
            StyleURI(rawValue: "mapbox://styles/mapbox-dash/standard-satellite-navigation")!,
        ]
        var overrides: [StyleURI: MapStyle] = [:]
        for uri in implicitlyLoadedStyleURIs {
            overrides[uri] = .empty
        }
        MapStyle._overrides = overrides
    }

    public static func restoreDefaultStyles() {
        MapStyle._overrides = [:]
    }
}
