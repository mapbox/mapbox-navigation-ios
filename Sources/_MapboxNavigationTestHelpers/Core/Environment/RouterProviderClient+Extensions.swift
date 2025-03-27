@testable import MapboxNavigationCore

extension RouterProviderClient {
    public static func value(with routerClient: RouterClient) -> RouterProviderClient {
        Self(
            build: { _ in
                return routerClient
            }
        )
    }

    public static var testValue: RouterProviderClient {
        Self(
            build: { _ in
                return RouterClient.testValue
            }
        )
    }

    public static var noopValue: RouterProviderClient {
        Self(
            build: { _ in
                return RouterClient.noopValue
            }
        )
    }
}
