import _MapboxNavigationHelpers
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

    private struct State {
        var isRerouting: Bool = false
        var navigationRoute: NavigationRoute?
        var currentLocation: CLLocation?
        var lastProactiveRerouteDate: Date?
        var routeTask: RoutingProvider.FetchTask?
    }

    private let state: UnfairLocked<State>

    var isRerouting: Bool {
        get { state.read(\.isRerouting) }
        set { state.mutate { $0.isRerouting = newValue } }
    }

    var navigationRoute: NavigationRoute? {
        get { state.read(\.navigationRoute) }
        set { state.mutate { $0.navigationRoute = newValue } }
    }

    var currentLocation: CLLocation? {
        get { state.read(\.currentLocation) }
        set { state.mutate { $0.currentLocation = newValue } }
    }

    private let _fasterRoutes: PassthroughSubject<NavigationRoutes, Never>
    var fasterRoutes: AnyPublisher<NavigationRoutes, Never> {
        _fasterRoutes.eraseToAnyPublisher()
    }

    init(configuration: Configuration) {
        self.configuration = configuration
        self.state = UnfairLocked(State())
        self._fasterRoutes = .init()
    }

    func checkForFasterRoute(from routeProgress: RouteProgress) {
        Task { [state] in
            let currentState = state.read {
                (
                    route: $0.navigationRoute,
                    location: $0.currentLocation,
                    lastProactiveRerouteDate: $0.lastProactiveRerouteDate
                )
            }
            guard let routeOptions = currentState.route?.routeOptions,
                  let location = currentState.location else { return }

            // Only check for faster alternatives if the user has plenty of time left on the route.
            guard routeProgress.durationRemaining > configuration.settings.minimumRouteDurationRemaining else { return }
            // If the user is approaching a maneuver, don't check for a faster alternatives
            guard routeProgress.currentLegProgress.currentStepProgress.durationRemaining > configuration.settings
                .minimumManeuverOffset else { return }

            guard let currentUpcomingManeuver = routeProgress.currentLegProgress.upcomingStep else {
                return
            }

            guard let lastRouteValidationDate = currentState.lastProactiveRerouteDate else {
                state.mutate { $0.lastProactiveRerouteDate = location.timestamp }
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
            let didBeginReroute = state.mutate {
                if $0.isRerouting { return false }
                $0.isRerouting = true
                return true
            }
            guard didBeginReroute else { return }

            defer { state.mutate { $0.isRerouting = false } }

            guard let navigationRoutes = await calculateRoutes(
                from: location,
                along: routeProgress,
                options: routeOptions
            ) else {
                return
            }
            let route = navigationRoutes.mainRoute.route

            state.mutate { $0.lastProactiveRerouteDate = nil }

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
        state.mutate { $0.routeTask?.cancel() }

        let options = progress.reroutingOptions(from: origin, routeOptions: options)

        // https://github.com/mapbox/mapbox-navigation-ios/issues/3966
        if isRerouting,
           options.profileIdentifier.isAutomobile || options.profileIdentifier.isAutomobileAvoidingTraffic
        {
            options.initialManeuverAvoidanceRadius = configuration.initialManeuverAvoidanceRadius * origin.speed
        }

        let task = configuration.routingProvider.calculateRoutes(options: options)
        state.mutate { $0.routeTask = task }
        defer { state.mutate { $0.routeTask = nil } }

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
