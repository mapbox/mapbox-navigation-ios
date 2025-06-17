@preconcurrency import Combine
import MapboxDirections
import MapboxMaps

/// The default implementation of ``RouteCalloutViewProvider`` that creates and manages Mapbox-styled route callout
/// views.
///
/// This class provides the standard Mapbox appearance for route callouts, displaying information like estimated travel
/// times,
/// toll indicators, and relative travel time differences between routes. The callouts adapt their appearance based on
/// the navigation session state:
/// - In free drive or idle state: Shows ETA, toll indicators, and "Best", "Fastest", or "Suggested" labels.
/// - In active guidance: Shows relative time differences between the current route and alternatives and also toll
/// indicators.
///
/// Use this provider with ``NavigationMapView`` to display the default Mapbox route callouts:
/// ```swift
/// navigationMapView.apiRouteCalloutViewProviderEnabled = true
/// let sessionController = navigationProvider.mapboxNavigation.tripSession()
/// navigationMapView.routeCalloutViewProvider = DefaultRouteCalloutViewProvider(sessionController: sessionController)
/// navigationMapView.showRoutes(routes)
/// ```
@_spi(ExperimentalMapboxAPI)
public final class DefaultRouteCalloutViewProvider: RouteCalloutViewProvider {
    private static let similarTimeThreshold: TimeInterval = 180.0

    /// The unique identifier for this provider, conforming to ``RedrawRequester`` protocol.
    public let id: UUID = .init()
    private let sessionController: SessionController
    private var sessionSubscription: AnyCancellable?

    /// Publisher that emits a signal when the route callouts need to be redrawn.
    ///
    /// This publisher emits the provider's ID when the navigation session changes or when a redraw is otherwise
    /// required.
    /// The map view subscribes to this publisher to know when to refresh the displayed callouts.
    public var redrawRequestPublisher: AnyPublisher<Void, Never> {
        _redrawRequestPublisher.eraseToAnyPublisher()
    }

    private var _redrawRequestPublisher: PassthroughSubject<Void, Never> = .init()

    @MainActor
    var mapStyleConfig: MapStyleConfig?

    /// The configurations for how route callout views should be anchored to the map.
    ///
    /// These configurations determine which anchor positions are available for positioning the callouts
    /// along routes. Each configuration includes an anchor position like `.topLeft`, `.bottomRight`, etc.
    public let anchorConfigs: [ViewAnnotationAnchorConfig]

    /// The default anchor configurations used when none are specifically provided.
    ///
    /// By default, callouts can be anchored at all four corners: `.topLeft`, `.topRight`, `.bottomLeft`, and
    /// `.bottomRight`.
    /// This allows the map view to choose the best position for each callout based on the route geometry.
    public nonisolated static var defaultAnchorConfigs: [ViewAnnotationAnchorConfig] {
        [
            .init(anchor: .topLeft),
            .init(anchor: .topRight),
            .init(anchor: .bottomLeft),
            .init(anchor: .bottomRight),
        ]
    }

    /// Creates a new default route callout view provider.
    ///
    /// - Parameters:
    ///   - sessionController: The controller that manages the current navigation session state.
    ///     This is used to determine the appropriate information to display in callouts.
    ///   - anchorConfigs: Configurations for how callout views should be anchored to the map.
    ///     Defaults to ``defaultAnchorConfigs`` if not specified.
    public init(
        sessionController: SessionController,
        anchorConfigs: [ViewAnnotationAnchorConfig] = defaultAnchorConfigs
    ) {
        self.anchorConfigs = anchorConfigs

        self.sessionController = sessionController
        self.sessionSubscription = self.sessionController.session
            .dropFirst(1) // avoids triggering redraw for initial current session state (which is sent immediately)
            .map { _ in () }
            .subscribe(_redrawRequestPublisher)
    }

    /// Creates route callout view containers for the provided navigation routes.
    ///
    /// This method generates appropriate callout views for each route based on the current navigation session state.
    ///
    /// - Parameter navigationRoutes: The navigation routes for which to create callout views.
    /// - Returns: A dictionary mapping route IDs to their corresponding callout view containers.
    public func createRouteCalloutViewContainers(
        for navigationRoutes: NavigationRoutes
    ) -> [RouteId: RouteCalloutViewContainer] {
        var containers: [RouteId: RouteCalloutViewContainer] = [:]
        guard mapStyleConfig != nil else { return containers }

        let mainRoute = navigationRoutes.mainRoute
        let primaryRouteTravelTime = navigationRoutes.mainRoute.route.expectedTravelTime

        let mainRouteCalloutData = RouteCalloutData(
            route: navigationRoutes.mainRoute.route,
            isPrimary: true,
            isSingle: navigationRoutes.alternativeRoutes.isEmpty,
            isSuggested: navigationRoutes.mainRoute.isSuggested,
            expectedTravelTimesOfOtherRoutes: navigationRoutes.alternativeRoutes.map { $0.route.expectedTravelTime },
            expectedTravelTimeOfPrimaryRoute: primaryRouteTravelTime
        )
        let container = routeCalloutViewContainer(for: mainRouteCalloutData)
        containers[mainRoute.routeId] = container

        for alternativeRoute in navigationRoutes.alternativeRoutes {
            var otherRoutesTravelTimes = navigationRoutes.alternativeRoutes
                .filter { $0 != alternativeRoute }
                .map { $0.route.expectedTravelTime }

            otherRoutesTravelTimes += [primaryRouteTravelTime]

            let alternativeRouteCalloutData = RouteCalloutData(
                route: alternativeRoute.route,
                isPrimary: false,
                isSingle: false,
                isSuggested: alternativeRoute.isSuggested,
                expectedTravelTimesOfOtherRoutes: otherRoutesTravelTimes,
                expectedTravelTimeOfPrimaryRoute: primaryRouteTravelTime,
                deviationOffset: alternativeRoute.deviationOffset()
            )
            let container = routeCalloutViewContainer(for: alternativeRouteCalloutData)
            containers[alternativeRoute.routeId] = container
        }

        return containers
    }

    private func routeCalloutViewContainer(
        for data: RouteCalloutData
    ) -> RouteCalloutViewContainer? {
        guard let mapStyleConfig else { return nil }

        let session = sessionController.currentSession
        switch session.state {
        case .idle, .freeDrive:

            let travelTime = data.route.expectedTravelTime

            var isUniqueFastestRoute = false
            if !data.isSingle {
                let isFastest = data.expectedTravelTimesOfOtherRoutes.allSatisfy {
                    $0 > travelTime
                }

                isUniqueFastestRoute = isFastest && data.expectedTravelTimesOfOtherRoutes
                    .allSatisfy {
                        $0.wholeMinutes != travelTime.wholeMinutes
                    }
            }

            let captionText: String?
            captionText = if data.isSingle {
                "Best".localizedValue(prefix: "ROUTE_CALLOUT_")
            } else if isUniqueFastestRoute {
                "Fastest".localizedValue(prefix: "ROUTE_CALLOUT_")
            } else if data.isSuggested {
                "Suggested".localizedValue(prefix: "ROUTE_CALLOUT_")
            } else {
                nil
            }

            let containsTolls = data.route.containsTolls

            let calloutView = RouteCalloutView(
                eta: travelTime,
                captionText: captionText,
                isSelected: data.isPrimary,
                containsTolls: containsTolls,
                mapStyleConfig: mapStyleConfig
            )

            let viewHolder = RouteCalloutViewContainer(view: calloutView) { config in
                calloutView.anchor = config.anchor
            }
            return viewHolder

        case .activeGuidance:
            guard !data.isPrimary else { return nil }

            let calloutText: String
            var captionText: String?

            let expectedTravelTime = data.route.expectedTravelTime
            let travelTimeDelta = expectedTravelTime - data.expectedTravelTimeOfPrimaryRoute

            if abs(travelTimeDelta) >= Self.similarTimeThreshold {
                calloutText = DateComponentsFormatter.travelTimeString(
                    travelTimeDelta,
                    signed: false
                )
                captionText = travelTimeDelta < 0
                    ? "faster".localizedValue(prefix: "ROUTE_CALLOUT_")
                    : "slower".localizedValue(prefix: "ROUTE_CALLOUT_")
            } else {
                calloutText = "Similar ETA".localizedValue(prefix: "ROUTE_CALLOUT_")
            }
            let calloutView = RouteCalloutView(
                text: calloutText,
                captionText: captionText,
                isSelected: false,
                containsTolls: data.route.containsTolls,
                mapStyleConfig: mapStyleConfig
            )

            var allowedRouteOffsetRange = RouteCalloutViewContainer.defaultAllowedRouteOffsetRange
            if let deviationOffset = data.deviationOffset {
                allowedRouteOffsetRange = (deviationOffset + 0.01)...(deviationOffset + 0.05)
            }

            let viewHolder = RouteCalloutViewContainer(
                view: calloutView,
                allowedRouteOffsetRange: allowedRouteOffsetRange
            ) { config in
                calloutView.anchor = config.anchor
            }
            return viewHolder
        }
    }
}

extension Route {
    fileprivate var containsTolls: Bool {
        !(tollIntersections?.isEmpty ?? true)
    }
}

extension TimeInterval {
    fileprivate var wholeMinutes: Int {
        Int(self / 60)
    }
}

private struct RouteCalloutData {
    var route: Route
    var isPrimary: Bool
    var isSingle: Bool
    var isSuggested: Bool
    var expectedTravelTimesOfOtherRoutes: [TimeInterval]
    var expectedTravelTimeOfPrimaryRoute: TimeInterval
    var deviationOffset: Double?
}
