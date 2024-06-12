import Combine
import CoreLocation
import Foundation
import MapboxDirections

public protocol FasterRouteProvider: AnyObject {
    var isRerouting: Bool { get set }
    var navigationRoute: NavigationRoute? { get set }
    var currentLocation: CLLocation? { get set }
    var fasterRoutes: AnyPublisher<NavigationRoutes, Never> { get }

    func checkForFasterRoute(
        from routeProgress: RouteProgress
    )
}

final class FasterRouteController: FasterRouteProvider, @unchecked Sendable {
    struct Configuration {
        let settings: FasterRouteDetectionConfig
        let initialManeuverAvoidanceRadius: TimeInterval
        let routingProvider: RoutingProvider
    }

    let configuration: Configuration

    private var lastProactiveRerouteDate: Date?
    private var routeTask: RoutingProvider.FetchTask?

    var isRerouting: Bool
    var navigationRoute: NavigationRoute?
    var currentLocation: CLLocation?

    private var _fasterRoutes: PassthroughSubject<NavigationRoutes, Never>
    var fasterRoutes: AnyPublisher<NavigationRoutes, Never> {
        _fasterRoutes.eraseToAnyPublisher()
    }

    init(configuration: Configuration) {
        self.configuration = configuration

        self.lastProactiveRerouteDate = nil
        self.isRerouting = false
        self.routeTask = nil
        self._fasterRoutes = .init()
    }

    func checkForFasterRoute(
        from routeProgress: RouteProgress
    ) {
        Task {
            guard let routeOptions = navigationRoute?.routeOptions,
                  let location = currentLocation else { return }

            // Only check for faster alternatives if the user has plenty of time left on the route.
            guard routeProgress.durationRemaining > configuration.settings.minimumRouteDurationRemaining else { return }
            // If the user is approaching a maneuver, don't check for a faster alternatives
            guard routeProgress.currentLegProgress.currentStepProgress.durationRemaining > configuration.settings
                .minimumManeuverOffset else { return }

            guard let currentUpcomingManeuver = routeProgress.currentLegProgress.upcomingStep else {
                return
            }

            guard let lastRouteValidationDate = lastProactiveRerouteDate else {
                self.lastProactiveRerouteDate = location.timestamp
                return
            }

            // Only check every so often for a faster route.
            guard location.timestamp.timeIntervalSince(lastRouteValidationDate) >= configuration.settings
                .proactiveReroutingInterval
            else {
                return
            }

            let durationRemaining = routeProgress.durationRemaining

            // Avoid interrupting an ongoing reroute
            if isRerouting { return }
            isRerouting = true

            defer { self.isRerouting = false }

            guard let navigationRoutes = await calculateRoutes(
                from: location,
                along: routeProgress,
                options: routeOptions
            ) else {
                return
            }
            let route = navigationRoutes.mainRoute.route

            self.lastProactiveRerouteDate = nil

            guard let firstLeg = route.legs.first, let firstStep = firstLeg.steps.first else {
                return
            }

            let routeIsFaster = firstStep.expectedTravelTime >= self.configuration.settings.minimumManeuverOffset &&
                currentUpcomingManeuver == firstLeg.steps[1] && route.expectedTravelTime <= 0.9 * durationRemaining

            guard routeIsFaster else {
                return
            }

            let completion = { @MainActor in
                self._fasterRoutes.send(navigationRoutes)
            }

            switch self.configuration.settings.fasterRouteApproval {
            case .automatically:
                await completion()
            case .manually(let approval):
                if await approval((location, navigationRoutes.mainRoute)) {
                    await completion()
                }
            }
        }
    }

    private func calculateRoutes(
        from origin: CLLocation,
        along progress: RouteProgress,
        options: RouteOptions
    ) async -> NavigationRoutes? {
        routeTask?.cancel()

        let options = progress.reroutingOptions(from: origin, routeOptions: options)

        // https://github.com/mapbox/mapbox-navigation-ios/issues/3966
        if isRerouting,
           options.profileIdentifier == .automobile || options.profileIdentifier == .automobileAvoidingTraffic
        {
            options.initialManeuverAvoidanceRadius = configuration.initialManeuverAvoidanceRadius * origin.speed
        }

        let task = configuration.routingProvider.calculateRoutes(options: options)
        routeTask = task
        defer { self.routeTask = nil }

        do {
            let routes = try await task.value
            return await routes.selectingMostSimilar(to: progress.route)
        } catch {
            Log.warning(
                "Failed to fetch proactive reroute with error: \(error)",
                category: .navigation
            )
            return nil
        }
    }
}
