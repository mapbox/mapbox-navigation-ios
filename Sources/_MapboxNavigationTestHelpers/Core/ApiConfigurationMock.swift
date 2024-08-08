import Foundation
import MapboxCommon
import MapboxDirections
@_spi(MapboxInternal) import MapboxNavigationCore

extension ApiConfiguration {
    public static func mock(accessToken: String = .mockedAccessToken, host: URL? = nil) -> Self {
        .init(accessToken: accessToken, endPoint: host)
    }
}

extension String {
    public static var mockedAccessToken: String { "pk.feedCafeDadeDeadBeef-BadeBede.FadeCafeDadeDeed-BadeBede" }
}

extension Credentials {
    public static func mock(accessToken: String = .mockedAccessToken, host: URL? = nil) -> Self {
        .init(accessToken: accessToken, host: host)
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
