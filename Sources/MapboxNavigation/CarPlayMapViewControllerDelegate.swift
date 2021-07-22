import MapboxMaps
import MapboxCoreNavigation

/**
 The `CarPlayMapViewControllerDelegate` protocol provides methods for reacting to events during free-drive navigation or route previewing in `CarPlayMapViewController`.
 */
@available(iOS 12.0, *)
public protocol CarPlayMapViewControllerDelegate: AnyObject, UnimplementedLogging {
    
    /**
     Tells the receiver that the final destination `PointAnnotation` was added to the `CarPlayMapViewController`.
     
     - parameter carPlayMapViewController: The `CarPlayMapViewController` object.
     - parameter finalDestinationAnnotation: The point annotation that was added to the map view.
     - parameter pointAnnotationManager: The object that manages the point annotation in the map view.
     */
    func carPlayMapViewController(_ carPlayMapViewController: CarPlayMapViewController,
                                  didAdd finalDestinationAnnotation: PointAnnotation,
                                  pointAnnotationManager: PointAnnotationManager)
}

@available(iOS 12.0, *)
public extension CarPlayMapViewControllerDelegate {
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func carPlayMapViewController(_ carPlayMapViewController: CarPlayMapViewController,
                                  didAdd finalDestinationAnnotation: PointAnnotation,
                                  pointAnnotationManager: PointAnnotationManager) {
        logUnimplemented(protocolType: CarPlayMapViewController.self, level: .debug)
    }
}
