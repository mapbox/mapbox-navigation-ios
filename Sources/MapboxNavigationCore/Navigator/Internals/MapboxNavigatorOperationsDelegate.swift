import Foundation
import MapboxCommon_Private
import MapboxNavigationNative
import MapboxNavigationNative_Private

final class MapboxNavigatorOperationsDelegate: NSObject, NavigatorOperationsDelegate {
    enum Failure: LocalizedError {
        case providerUnavailable
        case noRoutes
        case routeParsingFailed(underlying: Error)

        var errorDescription: String? {
            switch self {
            case .providerUnavailable:
                return "Navigation provider is unavailable"
            case .noRoutes:
                return "No routes provided"
            case .routeParsingFailed(let underlying):
                return "Failed to parse routes: \(underlying.localizedDescription)"
            }
        }
    }

    private weak var provider: MapboxNavigationProvider?

    init(provider: MapboxNavigationProvider) {
        self.provider = provider
        super.init()
    }

    func startActiveGuidance(
        forRoutes routes: [any RouteInterface],
        initialLegIndex: UInt32,
        callback: @escaping NavigatorOperationsStartActiveGuidanceCallback
    ) {
        Task { @MainActor [weak self] in
            guard let navigator = self?.provider?.navigator() else {
                callback(expectedError(Failure.providerUnavailable))
                return
            }
            guard let primary = routes.first else {
                callback(expectedError(Failure.noRoutes))
                return
            }

            // Presenters promote a preview after the app has already started guidance on the same routes,
            // so restarting here would reset route progress and the billing session.
            if let activeRoutes = navigator.currentNavigationRoutes,
               activeRoutes.mainRoute.routeId.rawValue == primary.getRouteId()
            {
                callback(Expected(value: NavigatorOperationsStartActiveGuidanceResult(routeIds: activeRoutes.routeIds)))
                return
            }

            let navigationRoutes: NavigationRoutes
            do {
                navigationRoutes = try await NavigationRoutes(routeInterfaces: routes)
            } catch {
                callback(expectedError(Failure.routeParsingFailed(underlying: error)))
                return
            }

            navigator.startActiveGuidance(
                with: navigationRoutes,
                startLegIndex: Int(initialLegIndex)
            ) { result in
                switch result {
                case .success(let routeIds):
                    callback(Expected(value: NavigatorOperationsStartActiveGuidanceResult(routeIds: routeIds)))
                case .failure(let error):
                    callback(expectedError(error))
                }
            }
        }
    }

    func switchToAlternativeRoute(
        forRouteId routeId: String,
        callback: @escaping NavigatorOperationsSwitchToAlternativeRouteCallback
    ) {
        Task { @MainActor [weak self] in
            guard let navigator = self?.provider?.navigator() else {
                callback(expectedError(Failure.providerUnavailable))
                return
            }

            navigator.selectAlternativeRoute(with: RouteId(rawValue: routeId)) { result in
                switch result {
                case .success:
                    callback(Expected(value: NSNull()))
                case .failure(let error):
                    callback(expectedError(error))
                }
            }
        }
    }
}

private func expectedError<Value>(_ error: Error) -> Expected<Value, NSString> {
    Expected(error: error.localizedDescription as NSString)
}
