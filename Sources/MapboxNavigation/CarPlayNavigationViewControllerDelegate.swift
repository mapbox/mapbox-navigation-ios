import MapboxCoreNavigation
import MapboxDirections
import MapboxMaps

/**
 The `CarPlayNavigationViewControllerDelegate` protocol provides methods for reacting to significant events during turn-by-turn navigation with `CarPlayNavigationViewController`.
 */
@available(iOS 12.0, *)
public protocol CarPlayNavigationViewControllerDelegate: AnyObject, UnimplementedLogging {
    
    /**
     Called when the CarPlay navigation view controller is dismissed, such as when the user ends a trip.
     
     - parameter carPlayNavigationViewController: The CarPlay navigation view controller that was dismissed.
     - parameter canceled: True if the user dismissed the CarPlay navigation view controller by tapping the Cancel button; false if the navigation view controller dismissed by some other means.
     */
    func carPlayNavigationViewControllerDidDismiss(_ carPlayNavigationViewController: CarPlayNavigationViewController, byCanceling canceled: Bool)
    
    /**
     Called when the CarPlay navigation view controller detects an arrival.
     
     - parameter carPlayNavigationViewController: The CarPlay navigation view controller that has arrived at a waypoint.
     - parameter waypoint: The waypoint that the user has arrived at.
     - returns: A boolean value indicating whether to show an arrival UI.
     */
    func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController, shouldPresentArrivalUIFor waypoint: Waypoint) -> Bool
    
    /**
     Tells the receiver that the final destination `PointAnnotation` was added to the `CarPlayNavigationViewController`.
     
     - parameter carPlayNavigationViewController: The `CarPlayNavigationViewController` object.
     - parameter finalDestinationAnnotation: `PointAnnotation`, which was added to the `MapView`.
     - parameter pointAnnotationManager: `PointAnnotationManager` instance, which is responsible for `PointAnnotation`s management in the `NavigationMapView`.
     */
    func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                         didAdd finalDestinationAnnotation: PointAnnotation,
                                         pointAnnotationManager: PointAnnotationManager)
}

@available(iOS 12.0, *)
public extension CarPlayNavigationViewControllerDelegate {
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func carPlayNavigationViewControllerDidDismiss(_ carPlayNavigationViewController: CarPlayNavigationViewController, byCanceling canceled: Bool) {
        logUnimplemented(protocolType: CarPlayNavigationViewControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                         didAdd finalDestinationAnnotation: PointAnnotation,
                                         pointAnnotationManager: PointAnnotationManager) {
        logUnimplemented(protocolType: CarPlayNavigationViewControllerDelegate.self, level: .debug)
    }
}
