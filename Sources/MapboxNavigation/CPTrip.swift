import MapboxDirections
#if canImport(CarPlay)
import CarPlay
#endif

@available(iOS 12.0, *)
extension CPTrip {
    convenience init(routes: [Route], routeOptions: RouteOptions, waypoints: [Waypoint]) {
        let routeChoices = routes.enumerated().map { (routeIndex, route) -> CPRouteChoice in
            let summaryVariants = [
                DateComponentsFormatter.fullDateComponentsFormatter.string(from: route.expectedTravelTime)!,
                DateComponentsFormatter.shortDateComponentsFormatter.string(from: route.expectedTravelTime)!,
                DateComponentsFormatter.briefDateComponentsFormatter.string(from: route.expectedTravelTime)!
            ]
            let routeChoice = CPRouteChoice(summaryVariants: summaryVariants,
                                            additionalInformationVariants: [route.description],
                                            selectionSummaryVariants: [route.description])
            let info: (Route, Int, RouteOptions) = (route: route, routeIndex: routeIndex, options: routeOptions)
            routeChoice.userInfo = info
            return routeChoice
        }
        
        let waypoints = routeOptions.waypoints
        let origin = MKMapItem(placemark: MKPlacemark(coordinate: waypoints.first!.coordinate))
        origin.name = waypoints.first?.name
        let destination = MKMapItem(placemark: MKPlacemark(coordinate: waypoints.last!.coordinate))
        destination.name = waypoints.last?.name
        
        self.init(origin: origin, destination: destination, routeChoices: routeChoices)
        userInfo = routeOptions
    }
}
