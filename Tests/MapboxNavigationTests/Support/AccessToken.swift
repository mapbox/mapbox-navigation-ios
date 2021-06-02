import Foundation
import MapboxDirections

extension Directions {
    static var mocked: Directions {
        return .init(credentials: .mocked)
    }
}

extension DirectionsCredentials {
    static var mocked: DirectionsCredentials {
        return .init(accessToken: .mockedAccessToken, host: nil)
    }
}

extension String {
    static var mockedAccessToken: String { "pk.feedCafeDadeDeadBeef-BadeBede.FadeCafeDadeDeed-BadeBede" }
}
