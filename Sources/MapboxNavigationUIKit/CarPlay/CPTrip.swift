import CarPlay
import MapboxDirections
import MapboxNavigationCore

extension CPTrip {
    convenience init(routes: NavigationRoutes) async {
        let waypoints: [Waypoint] = routes.waypoints

        var routeChoices: [CPRouteChoice] = [
            Self.makeMainRouteChoice(routes: routes),
        ]

        for alternativeRoute in routes.alternativeRoutes {
            let choice = await Self.makeRouteChoice(routes: routes, alternateRoute: alternativeRoute)
            routeChoices.append(choice)
        }

        guard let originCoordinate = waypoints.first?.coordinate,
              let destinationCoordinate = waypoints.last?.coordinate
        else {
            preconditionFailure("Origin and destination coordinates should be valid.")
        }

        let originMapItem = MKMapItem(placemark: MKPlacemark(coordinate: originCoordinate))
        originMapItem.name = waypoints.first?.name

        let destinationMapItem = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
        destinationMapItem.name = waypoints.last?.name

        self.init(
            origin: originMapItem,
            destination: destinationMapItem,
            routeChoices: routeChoices
        )

        self.userInfo = routes
    }

    private static func makeRouteChoice(
        routes: NavigationRoutes,
        alternateRoute: AlternativeRoute
    ) async -> CPRouteChoice {
        let routeChoice = prepareRouteChiceModel(for: alternateRoute.route)

        let key: String = CPRouteChoice.RouteResponseUserInfo.key
        if let newRoutes = await routes.selecting(alternativeRoute: alternateRoute) {
            let value: CPRouteChoice.RouteResponseUserInfo = .init(navigationRoutes: newRoutes, searchResultRecord: nil)
            let userInfo: CarPlayUserInfo = [key: value]
            routeChoice.userInfo = userInfo
        }
        return routeChoice
    }

    private static func makeMainRouteChoice(routes: NavigationRoutes) -> CPRouteChoice {
        let routeChoice = prepareRouteChiceModel(for: routes.mainRoute.route)
        let key: String = CPRouteChoice.RouteResponseUserInfo.key
        let value: CPRouteChoice.RouteResponseUserInfo = .init(navigationRoutes: routes, searchResultRecord: nil)
        let userInfo: CarPlayUserInfo = [key: value]
        routeChoice.userInfo = userInfo
        return routeChoice
    }

    private static func prepareRouteChiceModel(for route: Route) -> CPRouteChoice {
        let summaryVariants = [
            DateComponentsFormatter.fullDateComponentsFormatter.string(from: route.expectedTravelTime)!,
            DateComponentsFormatter.shortDateComponentsFormatter.string(from: route.expectedTravelTime)!,
            DateComponentsFormatter.briefDateComponentsFormatter.string(from: route.expectedTravelTime)!,
        ]
        return CPRouteChoice(
            summaryVariants: summaryVariants,
            additionalInformationVariants: [route.description],
            selectionSummaryVariants: [Measurement(distance: route.distance).localized().description]
        )
    }
}

extension CPTrip {
    convenience init(searchResultRecord: SearchResultRecord) {
        let placemark: MKPlacemark = .init(coordinate: searchResultRecord.coordinate)
        let destination = MKMapItem(placemark: placemark)
        destination.name = searchResultRecord.name
        let routeChoice = CPRouteChoice(
            summaryVariants: [searchResultRecord.name],
            additionalInformationVariants: [searchResultRecord.descriptionText ?? ""],
            selectionSummaryVariants: []
        )

        let key: String = CPRouteChoice.RouteResponseUserInfo.key
        let value: CPRouteChoice.RouteResponseUserInfo = .init(
            navigationRoutes: nil,
            searchResultRecord: searchResultRecord
        )

        let userInfo: CarPlayUserInfo = [key: value]
        routeChoice.userInfo = userInfo
        self.init(
            origin: .forCurrentLocation(),
            destination: destination,
            routeChoices: [routeChoice]
        )

        self.userInfo = searchResultRecord
    }
}
