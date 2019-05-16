import MapboxDirections
#if canImport(CarPlay)
import CarPlay
#endif

@available(iOS 12.0, *)
extension CPTrip {
    static let fullDateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        formatter.allowedUnits = [.day, .hour, .minute]
        return formatter
    }()
    
    static let shortDateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .short
        formatter.allowedUnits = [.day, .hour, .minute]
        return formatter
    }()
    
    static let briefDateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .brief
        formatter.allowedUnits = [.day, .hour, .minute]
        return formatter
    }()
    
    convenience init(routes: [Route], routeOptions: RouteOptions, waypoints: [Waypoint]) {
        let routeChoices = routes.map { (route) -> CPRouteChoice in
            let summaryVariants = [
                CPTrip.fullDateComponentsFormatter.string(from: route.expectedTravelTime)!,
                CPTrip.shortDateComponentsFormatter.string(from: route.expectedTravelTime)!,
                CPTrip.briefDateComponentsFormatter.string(from: route.expectedTravelTime)!
            ]
            let routeChoice = CPRouteChoice(summaryVariants: summaryVariants,
                                            additionalInformationVariants: [route.description],
                                            selectionSummaryVariants: [route.description])
            routeChoice.userInfo = route
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
