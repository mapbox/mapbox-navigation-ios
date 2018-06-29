import Foundation
import MapboxNavigationNative
import MapboxDirections
import MapboxMobileEvents

class NativeRouteController: Routable {
    
    var delaysEventFlushing: Bool = false
    
    var outstandingFeedbackEvents: [CoreFeedbackEvent] = [CoreFeedbackEvent]()
    
    var routeProgress: RouteProgress
    
    var sessionState: SessionState
    
    var eventsManager: MMEEventsManager
    
    var usesDefaultUserInterface: Bool = false
    
    var locationManager: NavigationLocationManager
    
    var navigator: MBNavigator = MBNavigator()
    
    required init(along route: Route, directions: Directions, locationManager: NavigationLocationManager, eventsManager: MMEEventsManager) {
        self.sessionState = SessionState(currentRoute: route, originalRoute: route)
        self.locationManager = locationManager
        self.eventsManager = eventsManager
        self.routeProgress = RouteProgress(route: route)
    }
    
    func isOnRoute(_ location: CLLocation) -> Bool {
        return false
    }
}
