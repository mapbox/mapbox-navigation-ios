#if canImport(CarPlay)
import CarPlay
import MapboxDirections

@available(iOS 12.0, *)
public protocol CarPlaySearchControllerDelegate: class {
    func previewRoutes(to waypoint: Waypoint, completionHandler: @escaping () -> Void)
    func resetPanButtons(_ mapTemplate: CPMapTemplate)
    func pushTemplate(_ template: CPTemplate, animated: Bool)
    func popTemplate(animated: Bool)
}

@available(iOS 12.0, *)
@objc(MBCarPlaySearchController)
public class CarPlaySearchController: NSObject {
    
    var searchCompletionHandler: (([CPListItem]) -> Void)?
    var recentSearchItems: [CPListItem]?
    var recentSearchText: String?
    
    public weak var delegate: CarPlaySearchControllerDelegate?

}
#else
/**
 CarPlay support requires iOS 12.0 or above and the CarPlay framework.
 */
@objc(MBCarPlaySearchController)
public class CarPlaySearchController: NSObject {
    
}
#endif
