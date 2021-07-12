import Foundation

/**
 `CarPlaySearchController` is the main object responsible for managing the search feature on CarPlay.
 
 Messages declared in the `CPApplicationDelegate` protocol should be sent to this object in the containing application's application delegate. Implement `CarPlaySearchControllerDelegate` in the containing application and assign an instance to the `delegate` property of your `CarPlaySearchController` instance.
 
 - note: It is very important you have a single `CarPlaySearchController` instance at any given time. 
 */
@available(iOS 12.0, *)
public class CarPlaySearchController: NSObject {
    
    /**
     The `CarPlaySearchController` delegate.
     */
    public weak var delegate: CarPlaySearchControllerDelegate?
}
