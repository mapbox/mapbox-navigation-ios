import Foundation
@_spi(MapboxInternal) import MapboxNavigationCore

extension ApiConfiguration {
    public static func mock(accessToken: String = .mockedAccessToken, host: URL? = nil) -> Self {
        .init(accessToken: accessToken, endPoint: host)
    }
}

extension String {
    public static var mockedAccessToken: String { "pk.feedCafeDadeDeadBeef-BadeBede.FadeCafeDadeDeed-BadeBede" }
}
