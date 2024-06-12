import MapboxDirections
import MapboxNavigationNative

/// Allows fetching ``NavigationRoutes`` by given parameters.
public protocol RoutingProvider: Sendable {
    /// An asynchronous cancellable task for fetching a route.
    typealias FetchTask = Task<NavigationRoutes, Error>

    /// Creates a route by given `options`.
    ///
    /// This may be online or offline route, depending on the configuration and network availability.
    func calculateRoutes(options: RouteOptions) -> FetchTask

    /// Creates a map matched route by given `options`.
    ///
    /// This may be online or offline route, depending on the configuration and network availability.
    func calculateRoutes(options: MatchOptions) -> FetchTask
}

/// Defines source of routing engine to be used for requests.
public enum RoutingProviderSource: Equatable, Sendable {
    /// Fetch data online only.
    ///
    /// Such ``MapboxRoutingProvider`` is equivalent of using bare `Directions` wrapper.
    case online
    /// Use offline data only.
    ///
    /// In order for such ``MapboxRoutingProvider`` to function properly, proper navigation data should be available
    /// offline. `.offline` routing provider will not be able to refresh routes.
    case offline
    /// Attempts to use ``RoutingProviderSource/online`` with fallback to ``RoutingProviderSource/offline``.
    /// `.hybrid` routing provider will be able to refresh routes only using internet connection.
    case hybrid

    var nativeSource: RouterType {
        switch self {
        case .online:
            return .online
        case .offline:
            return .onboard
        case .hybrid:
            return .hybrid
        }
    }
}
