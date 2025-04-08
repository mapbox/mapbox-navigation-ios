import CarPlay
import MapboxDirections
import MapboxNavigationCore

extension CPTrip {
    convenience init(
        routes: NavigationRoutes,
        locale: Locale,
        distanceMeasurementSystem: MeasurementSystem
    ) async {
        let waypoints: [Waypoint] = routes.waypoints

        var routeChoices: [CPRouteChoice] = [
            Self.makeMainRouteChoice(
                routes: routes,
                locale: locale,
                distanceMeasurementSystem: distanceMeasurementSystem
            ),
        ]

        for alternativeRoute in routes.alternativeRoutes {
            let choice = await Self.makeRouteChoice(
                routes: routes, alternateRoute: alternativeRoute, locale: locale,
                distanceMeasurementSystem: distanceMeasurementSystem
            )
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
        alternateRoute: AlternativeRoute,
        locale: Locale,
        distanceMeasurementSystem: MeasurementSystem
    ) async -> CPRouteChoice {
        let routeChoice = prepareRouteChoiceModel(
            for: alternateRoute.route,
            locale: locale,
            distanceMeasurementSystem: distanceMeasurementSystem
        )

        let key: String = CPRouteChoice.RouteResponseUserInfo.key
        if let newRoutes = await routes.selecting(alternativeRoute: alternateRoute) {
            let value: CPRouteChoice.RouteResponseUserInfo = .init(navigationRoutes: newRoutes, searchResultRecord: nil)
            let userInfo: CarPlayUserInfo = [key: value]
            routeChoice.userInfo = userInfo
        }
        return routeChoice
    }

    private static func makeMainRouteChoice(
        routes: NavigationRoutes,
        locale: Locale,
        distanceMeasurementSystem: MeasurementSystem
    ) -> CPRouteChoice {
        let routeChoice = prepareRouteChoiceModel(
            for: routes.mainRoute.route,
            locale: locale,
            distanceMeasurementSystem: distanceMeasurementSystem
        )
        let key: String = CPRouteChoice.RouteResponseUserInfo.key
        let value: CPRouteChoice.RouteResponseUserInfo = .init(navigationRoutes: routes, searchResultRecord: nil)
        let userInfo: CarPlayUserInfo = [key: value]
        routeChoice.userInfo = userInfo
        return routeChoice
    }

    private static func prepareRouteChoiceModel(
        for route: Route,
        locale: Locale,
        distanceMeasurementSystem: MeasurementSystem
    ) -> CPRouteChoice {
        let summaryVariants = [
            DateComponentsFormatter.fullDateComponentsFormatter.string(from: route.expectedTravelTime),
            DateComponentsFormatter.shortDateComponentsFormatter.string(from: route.expectedTravelTime),
            DateComponentsFormatter.briefDateComponentsFormatter.string(from: route.expectedTravelTime),
        ]
        let measurement = Measurement(distance: route.distance)
        let localizedMeasurement = measurement.localized(
            into: locale,
            measurementSystem: distanceMeasurementSystem
        )
        return CPRouteChoice(
            summaryVariants: summaryVariants.compactMap { $0 },
            additionalInformationVariants: [route.description],
            selectionSummaryVariants: [localizedMeasurement.description]
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
