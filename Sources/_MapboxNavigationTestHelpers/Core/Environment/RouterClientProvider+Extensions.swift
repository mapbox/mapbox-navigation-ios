@testable import MapboxNavigationCore

extension RouterClientProvider {
    public static func value(with routerClient: RouterClient) -> RouterClientProvider {
        Self(
            build: { _ in
                return routerClient
            }
        )
    }

    public static var testValue: RouterClientProvider {
        Self(
            build: { _ in
                return RouterClient.testValue
            }
        )
    }

    public static var noopValue: RouterClientProvider {
        Self(
            build: { _ in
                return RouterClient.noopValue
            }
        )
    }
}
