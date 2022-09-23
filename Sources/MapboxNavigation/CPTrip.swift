import MapboxDirections
import MapboxCoreNavigation
import CarPlay

@available(iOS 12.0, *)
extension CPTrip {
    
    convenience init(indexedRouteResponse: IndexedRouteResponse) {
        var waypoints: [Waypoint]
        
        switch indexedRouteResponse.routeResponse.options {
        case .route(let routeOptions):
            waypoints = routeOptions.waypoints
        case .match(let matchOptions):
            waypoints = matchOptions.waypoints
        }
        
        let routeChoices = indexedRouteResponse.routeResponse.routes?.enumerated().map { (routeIndex, route) -> CPRouteChoice in
            let summaryVariants = [
                DateComponentsFormatter.fullDateComponentsFormatter.string(from: route.expectedTravelTime)!,
                DateComponentsFormatter.shortDateComponentsFormatter.string(from: route.expectedTravelTime)!,
                DateComponentsFormatter.briefDateComponentsFormatter.string(from: route.expectedTravelTime)!
            ]
            let routeChoice = CPRouteChoice(summaryVariants: summaryVariants,
                                            additionalInformationVariants: [route.description],
                                            selectionSummaryVariants: [route.description])
            
            let key: String = CPRouteChoice.IndexedRouteResponseUserInfo.key
            var selectedResponse = indexedRouteResponse
            selectedResponse.routeIndex = routeIndex
            let value: CPRouteChoice.IndexedRouteResponseUserInfo = .init(indexedRouteResponse: selectedResponse)
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
