import MapboxDirections
import CarPlay

@available(iOS 12.0, *)
extension CPTrip {
    
    convenience init(routeResponse: RouteResponse) {
        var waypoints: [Waypoint]
        var directionsOptions: DirectionsOptions
        
        switch routeResponse.options {
        case .route(let routeOptions):
            waypoints = routeOptions.waypoints
            directionsOptions = routeOptions
        case .match(let matchOptions):
            waypoints = matchOptions.waypoints
            directionsOptions = matchOptions
        }
        
        let routeChoices = routeResponse.routes?.enumerated().map { (routeIndex, route) -> CPRouteChoice in
            let summaryVariants = [
                DateComponentsFormatter.fullDateComponentsFormatter.string(from: route.expectedTravelTime)!,
                DateComponentsFormatter.shortDateComponentsFormatter.string(from: route.expectedTravelTime)!,
                DateComponentsFormatter.briefDateComponentsFormatter.string(from: route.expectedTravelTime)!
            ]
            let routeChoice = CPRouteChoice(summaryVariants: summaryVariants,
                                            additionalInformationVariants: [route.description],
                                            selectionSummaryVariants: [route.description])
            
            let key: String = CPRouteChoice.RouteResponseUserInfo.key
            let value: CPRouteChoice.RouteResponseUserInfo = .init(response: routeResponse,
                                                                   routeIndex: routeIndex,
                                                                   options: directionsOptions)
            let userInfo: CarPlayUserInfo = [key: value]
            routeChoice.userInfo = userInfo
            return routeChoice
        } ?? []
        
        guard let originCoordinate = waypoints.first?.coordinate,
              let destinationCoordinate = waypoints.last?.coordinate else {
                  preconditionFailure("Origin and destination coordinates should be valid.")
              }
        
        let originMapItem = MKMapItem(placemark: MKPlacemark(coordinate: originCoordinate))
        originMapItem.name = waypoints.first?.name
        
        let destinationMapItem = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
        destinationMapItem.name = waypoints.last?.name
        
        self.init(origin: originMapItem,
                  destination: destinationMapItem,
                  routeChoices: routeChoices)
    }
}
