import Foundation
import MapboxDirections

extension Directions {
    public static var mocked: Directions {
        return .init(credentials: .mocked)
    }
}

extension Credentials {
    public static var mocked: Credentials {
        return .init(accessToken: .mockedAccessToken, host: nil)
    }

    public static func injectSharedToken(_ accessToken: String) {
        UserDefaults.standard.set(accessToken, forKey: "MBXAccessToken")
    }
}

extension String {
    public static var mockedAccessToken: String { "pk.feedCafeDadeDeadBeef-BadeBede.FadeCafeDadeDeed-BadeBede" }
}
