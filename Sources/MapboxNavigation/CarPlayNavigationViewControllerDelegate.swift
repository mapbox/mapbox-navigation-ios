import MapboxCoreNavigation
import MapboxDirections
import MapboxMaps

/**
 The `CarPlayNavigationViewControllerDelegate` protocol provides methods for reacting to significant events during turn-by-turn navigation with `CarPlayNavigationViewController`.
 */
@available(iOS 12.0, *)
public protocol CarPlayNavigationViewControllerDelegate: AnyObject, UnimplementedLogging {
    
    /**
     Called when the CarPlay navigation view controller is about to be dismissed, such as when the user ends a trip.
     
     - parameter carPlayNavigationViewController: The CarPlay navigation view controller that was dismissed.
     - parameter canceled: True if the user dismissed the CarPlay navigation view controller by tapping the Cancel button; false if the navigation view controller dismissed by some other means.
     */
    func carPlayNavigationViewControllerWillDismiss(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                                    byCanceling canceled: Bool)
    
    /**
     Called when the CarPlay navigation view controller is dismissed, such as when the user ends a trip.
     
     - parameter carPlayNavigationViewController: The CarPlay navigation view controller that was dismissed.
     - parameter canceled: True if the user dismissed the CarPlay navigation view controller by tapping the Cancel button; false if the navigation view controller dismissed by some other means.
     */
    func carPlayNavigationViewControllerDidDismiss(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                                   byCanceling canceled: Bool)
    
    /**
     Called when the CarPlay navigation view controller detects an arrival.
     
     - parameter carPlayNavigationViewController: The CarPlay navigation view controller that has arrived at a waypoint.
     - parameter waypoint: The waypoint that the user has arrived at.
     - returns: A boolean value indicating whether to show an arrival UI.
     */
    func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                         shouldPresentArrivalUIFor waypoint: Waypoint) -> Bool
    
    /**
     Tells the receiver that the final destination `PointAnnotation` was added to the `CarPlayNavigationViewController`.
     
     - parameter carPlayNavigationViewController: The `CarPlayNavigationViewController` object.
     - parameter finalDestinationAnnotation: The point annotation that was added to the map view.
     - parameter pointAnnotationManager: The object that manages the point annotation in the map view.
     */
    func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                         didAdd finalDestinationAnnotation: PointAnnotation,
                                         pointAnnotationManager: PointAnnotationManager)

    /**
     Asks the receiver to return a `LineLayer` for the route line, given a layer identifier and a source identifier.
     This method is invoked when the map view loads and any time routes are added.
     
     - parameter carPlayNavigationViewController: The `CarPlayNavigationViewController` object.
     - parameter identifier: The `LineLayer` identifier.
     - parameter sourceIdentifier: Identifier of the source, which contains the route data that this method would style.
     - returns: A `LineLayer` that is applied to the route line.
     */
    func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                         routeLineLayerWithIdentifier identifier: String,
                                         sourceIdentifier: String) -> LineLayer?
    
    /**
     Asks the receiver to return a `LineLayer` for the casing layer that surrounds route line,
     given a layer identifier and a source identifier.
     This method is invoked when the map view loads and any time routes are added.
     
     - parameter carPlayNavigationViewController: The `CarPlayNavigationViewController` object.
     - parameter identifier: The `LineLayer` identifier.
     - parameter sourceIdentifier: Identifier of the source, which contains the route data that this method would style.
     - returns: A `LineLayer` that is applied as a casing around the route line.
     */
    func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                         routeCasingLineLayerWithIdentifier identifier: String,
                                         sourceIdentifier: String) -> LineLayer?
    
    /**
     Asks the receiver to return a `LineLayer` for highlighting restricted areas portions of the route,
     given a layer identifier and a source identifier.
     This method is invoked when the map view loads and any time routes are added.
     
     - parameter carPlayNavigationViewController: The `CarPlayNavigationViewController` object.
     - parameter identifier: The `LineLayer` identifier.
     - parameter sourceIdentifier: Identifier of the source, which contains the route data that this method would style.
     - returns: A `LineLayer` that is applied as restricted areas on the route line.
     */
    func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                         routeRestrictedAreasLineLayerWithIdentifier identifier: String,
                                         sourceIdentifier: String) -> LineLayer?
    
    /**
     Asks the receiver to adjust the default layer which will be added to the map view and return a `Layer`.
     This method is invoked when the map view loads and any time a layer will be added.
     
     - parameter carPlayNavigationViewController: The `CarPlayNavigationViewController` object.
     - parameter layer: A default `Layer` generated by the carPlayNavigationViewController.
     - returns: A `Layer` after adjusted and will be added to the map view by `MapboxNavigation`.
     */
    func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                         willAdd layer: Layer) -> Layer?
}

@available(iOS 12.0, *)
public extension CarPlayNavigationViewControllerDelegate {
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func carPlayNavigationViewControllerWillDismiss(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                                    byCanceling canceled: Bool) {
        logUnimplemented(protocolType: CarPlayNavigationViewControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func carPlayNavigationViewControllerDidDismiss(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                                   byCanceling canceled: Bool) {
        logUnimplemented(protocolType: CarPlayNavigationViewControllerDelegate.self, level: .debug)
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                         shouldPresentArrivalUIFor waypoint: Waypoint) {
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
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                         routeLineLayerWithIdentifier identifier: String,
                                         sourceIdentifier: String) -> LineLayer? {
        logUnimplemented(protocolType: CarPlayNavigationViewControllerDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                         routeCasingLineLayerWithIdentifier identifier: String,
                                         sourceIdentifier: String) -> LineLayer? {
        logUnimplemented(protocolType: CarPlayNavigationViewControllerDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                         routeRestrictedAreasLineLayerWithIdentifier identifier: String,
                                         sourceIdentifier: String) -> LineLayer? {
        logUnimplemented(protocolType: CarPlayNavigationViewControllerDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func carPlayNavigationViewController(_ carPlayNavigationViewController: CarPlayNavigationViewController,
                                         willAdd layer: Layer) -> Layer? {
        logUnimplemented(protocolType: CarPlayNavigationViewControllerDelegate.self, level: .debug)
        return nil
    }
}
