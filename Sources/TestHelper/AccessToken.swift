import Foundation
import MapboxCommon
import MapboxDirections
@_spi(MapboxInternal) import MapboxNavigationCore

extension Directions {
    public static func mock(credentials: Credentials = .mock()) -> Directions {
        .init(credentials: credentials)
    }
}

extension ApiConfiguration {
    public static func mock(accessToken: String = .mockedAccessToken, host: URL? = nil) -> Self {
        .init(accessToken: accessToken, endPoint: host)
    }
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

extension String {
    public static var mockedAccessToken: String { "pk.feedCafeDadeDeadBeef-BadeBede.FadeCafeDadeDeed-BadeBede" }
}
