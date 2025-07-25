import _MapboxNavigationHelpers
@preconcurrency import Combine
import MapboxDirections
import MapboxMaps
@_spi(ExperimentalMapboxAPI) import MapboxNavigationCore

@_spi(ExperimentalMapboxAPI)
public class CustomRouteCalloutViewProvider: RouteCalloutViewProvider {
    private static let similarTimeThreshold: TimeInterval = 180.0

    public let id: UUID = .init()

    public var redrawRequestPublisher: AnyPublisher<Void, Never> { _redrawRequestPublisher.eraseToAnyPublisher()
    }

    // Implementation of this protocol requirement allows notification
    // that route callouts should be redrawn (when style/layout is changed).
    private var _redrawRequestPublisher: PassthroughSubject<Void, Never> = .init()

    // Custom configuration of anchor points is required to take into account
    // non-standard anchor points in CustomRouteCalloutView which
    // are not placed exactly in corners or mid-edge points of the view.
    // Correct offsets needs to be declater so the map view can use them
    // when positioning route callouts.
    public let anchorConfigs: [ViewAnnotationAnchorConfig] = [
        .init(anchor: .topLeft, offsetX: -cornerAnchorOffsetX - padding, offsetY: anchorCircleOffset),
        .init(anchor: .topRight, offsetX: cornerAnchorOffsetX + padding, offsetY: anchorCircleOffset),
        .init(anchor: .bottomLeft, offsetX: -cornerAnchorOffsetX - padding, offsetY: -anchorCircleOffset),
        .init(anchor: .bottomRight, offsetX: cornerAnchorOffsetX + padding, offsetY: -anchorCircleOffset),
        .init(anchor: .left, offsetX: -anchorCircleOffset),
        .init(anchor: .right, offsetX: anchorCircleOffset),
    ]

    private static let cornerAnchorOffsetX: CGFloat = CustomRouteCalloutView.cornerTailHorizontalOffset
    private static let anchorCircleOffset: CGFloat = CustomRouteCalloutView.tailAnchorCircleRadius
    private static let padding: CGFloat =
        CustomRouteCalloutView.tailLineLength + 2 * CustomRouteCalloutView.tailAnchorCircleRadius

    enum PresentationStyle {
        case routePreview
        case activeGuidance
    }

    var presentationStyle: PresentationStyle = .routePreview {
        didSet {
            // Informing the framework that callouts should be redrawn.
            // CustomRouteCalloutViewProvider.
            _redrawRequestPublisher.send()
        }
    }

    public init() {}

    // This function is called when the framework requests custom route callout views
    // which are encapsulated together with options in RouteCalloutViewContainer.
    public func createRouteCalloutViewContainers(
        for navigationRoutes: NavigationRoutes
    ) -> [RouteId: RouteCalloutViewContainer] {
        var containers: [RouteId: RouteCalloutViewContainer] = [:]

        let mainRoute = navigationRoutes.mainRoute
        let primaryRouteTravelTime = navigationRoutes.mainRoute.route.expectedTravelTime

        let mainRouteCalloutData = RouteCalloutData(
            route: navigationRoutes.mainRoute.route,
            isPrimary: true,
            isSingle: navigationRoutes.alternativeRoutes.isEmpty,
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
                expectedTravelTimesOfOtherRoutes: otherRoutesTravelTimes,
                expectedTravelTimeOfPrimaryRoute: primaryRouteTravelTime,
                deviationOffset: alternativeRoute.deviationOffset
            )
            let container = routeCalloutViewContainer(for: alternativeRouteCalloutData)
            containers[alternativeRoute.routeId] = container
        }

        return containers
    }

    private func routeCalloutViewContainer(
        for data: RouteCalloutData
    ) -> RouteCalloutViewContainer? {
        // Supporting 2 presentation styles of route callouts.
        switch presentationStyle {
        case .routePreview:

            let travelTime = data.route.expectedTravelTime

            let containsTolls = data.route.containsTolls

            let calloutView = CustomRouteCalloutView(
                eta: travelTime,
                isSelected: data.isPrimary,
                containsTolls: containsTolls
            )

            let viewHolder = RouteCalloutViewContainer(view: calloutView) { config in
                // This is an important closure which sets the proper anchor
                // on the custom calloutr view, when the map view request it.
                calloutView.anchor = config.anchor
            }
            return viewHolder

        case .activeGuidance:
            guard !data.isPrimary else { return nil }

            let calloutText: String

            let expectedTravelTime = data.route.expectedTravelTime
            let travelTimeDelta = expectedTravelTime - data.expectedTravelTimeOfPrimaryRoute

            var isRelative = false

            if abs(travelTimeDelta) >= Self.similarTimeThreshold {
                calloutText = DateComponentsFormatter.travelTimeString(
                    travelTimeDelta,
                    signed: true
                )
                isRelative = true
            } else {
                calloutText = "Similar ETA"
            }
            let calloutView = CustomRouteCalloutView(
                text: calloutText,
                isSelected: false,
                containsTolls: data.route.containsTolls,
                isRelative: isRelative,
                isFaster: travelTimeDelta < 0
            )

            // Limiting allowed route offset range where callouts are displayed
            // so that the map view positions them close to deviation points of
            // alternative routes.
            var allowedRouteOffsetRange = RouteCalloutViewContainer.defaultAllowedRouteOffsetRange
            if let deviationOffset = data.deviationOffset {
                allowedRouteOffsetRange = (deviationOffset + 0.0001)...(deviationOffset + 0.1)
            }

            let viewContainer = RouteCalloutViewContainer(
                view: calloutView,
                allowedRouteOffsetRange: allowedRouteOffsetRange
            ) { config in
                // This is an important closure which sets the proper anchor
                // on the custom calloutr view, when the map view request it.
                calloutView.anchor = config.anchor
            }
            return viewContainer
        }
    }
}

extension Route {
    /// Helper property that indicates whether there are tolls on a route.
    fileprivate var containsTolls: Bool {
        !(tollIntersections?.isEmpty ?? true)
    }

    private var tollIntersections: [Intersection]? {
        let allSteps = legs.flatMap { return $0.steps }

        let allIntersections = allSteps.flatMap { $0.intersections ?? [] }
        let intersectionsWithTolls = allIntersections.filter { return $0.tollCollection != nil }

        return intersectionsWithTolls
    }
}

extension AlternativeRoute {
    /// Returns offset of the alternative route where it deviates from the main route.
    fileprivate var deviationOffset: Double {
        guard let coordinates = route.shape?.coordinates,
              !coordinates.isEmpty
        else {
            return 0
        }

        let splitGeometryIndex = alternativeRouteIntersectionIndices.routeGeometryIndex

        var totalDistance = 0.0
        var pointDistance: Double? = nil
        for index in stride(from: coordinates.count - 1, to: 0, by: -1) {
            let currCoordinate = coordinates[index]
            let prevCoordinate = coordinates[index - 1]
            totalDistance += currCoordinate.projectedDistance(to: prevCoordinate)

            if index == splitGeometryIndex + 1 {
                pointDistance = totalDistance
            }
        }
        guard let pointDistance, totalDistance != 0 else { return 0 }

        return (totalDistance - pointDistance) / totalDistance
    }
}

/// Helper struct to gather required data.
private struct RouteCalloutData {
    public var route: Route
    public var isPrimary: Bool
    public var isSingle: Bool
    public var expectedTravelTimesOfOtherRoutes: [TimeInterval]
    public var expectedTravelTimeOfPrimaryRoute: TimeInterval
    public var deviationOffset: Double?
}
