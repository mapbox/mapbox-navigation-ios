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
    
    /**
     The completion handler that will process the list of search results initiated on CarPlay.
     */
    var searchCompletionHandler: (([CPListItem]) -> Void)?
    
    /**
     The most recent search results.
     */
    var recentSearchItems: [CPListItem]?
    
    /**
     The most recent search text.
     */
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
