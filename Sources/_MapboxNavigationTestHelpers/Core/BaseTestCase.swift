import MapboxMaps
import XCTest

open class BaseTestCase: XCTestCase {
    override open func setUpWithError() throws {
        try super.setUpWithError()
        Self.injectSharedToken()
    }

    override open func setUp() async throws {
        try? await super.setUp()
        Self.injectSharedToken()
    }

    override open func tearDownWithError() throws {
        Self.clearInjectSharedToken()
    }

    public static func injectSharedToken(_ accessToken: String = .mockedAccessToken) {
        MapboxOptions.accessToken = .mockedAccessToken
        UserDefaults.standard.set(accessToken, forKey: "MBXAccessToken")
    }

    public static func clearInjectSharedToken() {
        MapboxOptions.accessToken = ""
        UserDefaults.standard.removeObject(forKey: "MBXAccessToken")
    }
}
