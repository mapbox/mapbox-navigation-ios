import Foundation
import MapboxCoreNavigation

/**
 The `NavigationCustomizable` protocol represents a UI-based mechanism that allows for customization of its visual style, as well as the navigation service that powers it.
 */
protocol NavigationCustomizable {
    /**
     The styles that the user interface can select from for display.
    */
    var styles: [Style]? { get }
    
    /**
     The navigation service that manages navigation along the route.
     */
    var navigationService: NavigationService? { get }
}
