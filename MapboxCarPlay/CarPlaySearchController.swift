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

/**
 `CarPlaySearchController` is the main object responsible for managing the search feature on CarPlay.
 
 Messages declared in the `CPApplicationDelegate` protocol should be sent to this object in the containing application's application delegate. Implement `CarPlaySearchControllerDelegate` in the containing application and assign an instance to the `delegate` property of your `CarPlaySearchController` instance.
 
 - note: It is very important you have a single `CarPlaySearchController` instance at any given time. 
 */
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
    
    /**
     The `CarPlaySearchController` delegate.
     */
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
