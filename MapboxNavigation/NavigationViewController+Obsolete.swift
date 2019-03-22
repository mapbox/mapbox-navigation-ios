import Foundation
import MapboxCoreNavigation
import MapboxDirections

//MARK: - Obsoleted Interfaces

public extension NavigationViewController {
    @available(*, deprecated: 0.1, message: "Use the new init(route:options:) initalizer.")
    @objc(initWithRoute:styles:navigationService:voiceController:)
    public convenience init(for route: Route,
                         styles: [Style]? = nil,
                         navigationService: NavigationService? = nil,
                         voiceController: RouteVoiceController? = nil) {
        let bridge = NavigationOptions()
        bridge.styles = styles
        bridge.navigationService = navigationService
        bridge.voiceController = voiceController
        
        self.init(for: route, options: bridge)
    }
    
    @available(*, obsoleted: 0.1, renamed: "navigationService", message: "NavigationViewController no longer directly manages a RouteController. See MapboxNavigationService, which contains a protocol-bound reference to the RouteController, for more information.")
    /// :nodoc: obsoleted
    @objc public final var routeController: RouteController! {
        get {
            fatalError()
        }
        set {
            fatalError()
        }
    }
    
    @available(*, obsoleted: 0.1, renamed: "navigationService.eventsManager", message: "NavigationViewController no-longer directly manages a NavigationEventsManager. See MapboxNavigationService, which contains a reference to the eventsManager, for more information.")
    /// :nodoc: obsoleted
    @objc public final var eventsManager: NavigationEventsManager! {
        get {
            fatalError()
        }
        set {
            fatalError()
        }
    }
    
    @available(*, obsoleted: 0.1, renamed: "navigationService.locationManager", message: "NavigationViewController no-longer directly manages an NavigationLocationManager. See MapboxNavigationService, which contains a reference to the locationManager, for more information.")
    /// :nodoc: obsoleted
    @objc public final var locationManager: NavigationLocationManager! {
        get {
            fatalError()
        }
        set {
            fatalError()
        }
    }
    
    @available(*, obsoleted: 0.1, renamed: "init(for:styles:navigationService:voiceController:)", message: "Intializing a NavigationViewController directly with a RouteController is no longer supported. Use a NavigationService instead.")
    /// :nodoc: Obsoleted method.
    @objc(initWithRoute:directions:styles:routeController:locationManager:voiceController:eventsManager:)
    public convenience init(for route: Route,
                            directions: Directions = Directions.shared,
                            styles: [Style]? = [DayStyle(), NightStyle()],
                            routeController: RouteController? = nil,
                            locationManager: NavigationLocationManager? = nil,
                            voiceController: RouteVoiceController? = nil,
                            eventsManager: NavigationEventsManager? = nil) {
        fatalError()
    }
    
    @available(iOS, introduced: 12.0, obsoleted: 0.1, message: "Have your NavigationViewControllerDelegate (such as a UIViewController subclass, or a discrete delegate) create and present a NavigationViewController.")
    public class func carPlayManager(_ carPlayManager: CarPlayManager, didBeginNavigationWith navigationService: NavigationService, window: UIWindow, delegate: NavigationViewControllerDelegate?) {
        fatalError()
    }
    
    @available(iOS, introduced: 12.0, obsoleted: 0.1, message: "Have your NavigationViewControllerDelegate (such as a UIViewController subclass, or a discrete delegate) dismiss the active NavigationViewController.")
    public class func carPlayManagerDidEndNavigation(_ carPlayManager: CarPlayManager, window: UIWindow) {
        fatalError()
    }

}
