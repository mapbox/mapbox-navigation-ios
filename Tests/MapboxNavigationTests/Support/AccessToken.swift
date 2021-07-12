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

    static func injectSharedToken(_ accessToken: String) {
        UserDefaults.standard.set(accessToken, forKey: "MBXAccessToken")
    }
}

extension String {
    static var mockedAccessToken: String { "pk.feedCafeDadeDeadBeef-BadeBede.FadeCafeDadeDeed-BadeBede" }
}
