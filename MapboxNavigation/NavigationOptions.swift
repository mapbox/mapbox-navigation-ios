import Foundation
import MapboxCoreNavigation

/**
 Customization options for the turn-by-turn navigation user experience in a `NavigationViewController`.
 
 A navigation options object is where you place customized components that the navigation view controller uses during its lifetime, such as styles or voice controllers. You would likely use this class if you need to specify a Mapbox access token programmatically instead of in the Info.plist file.
 
 - note: `NavigationOptions` is designed to be used with the `NavigationViewController` class to customize the user experience. To specify criteria when calculating routes, use the `NavigationRouteOptions` class.
 */

@objc(MBNavigationOptions)
open class NavigationOptions: NSObject, NavigationCustomizable {
    
    /**
     The styles that the view controller’s internal `StyleManager` object can select from for display.
     
     If this property is set to `nil`, a `DayStyle` and a `NightStyle` are created to be used as the view controller’s styles. This property is set to `nil` by default.
     */
    @objc open var styles: [Style]? = nil
    
    /**
     The navigation service that manages navigation along the route.
     */
    @objc open var navigationService: NavigationService?
    
    /**
     The voice controller that manages the delivery of voice instructions during navigation.
    */
    @objc open var voiceController: RouteVoiceController?
    
    /**
     The view controller to embed into the bottom section of the UI.
     
     If this property is set to `nil`, a `BottomBannerViewController` is created and embedded in the UI. This property is set to `nil` by default.
     */
    @objc open var bottomBanner: ContainerViewController?
    
    // This makes the compiler happy.
    required public override init() {
        super.init()
    }
    
    @objc public convenience init(styles: [Style]? = nil, navigationService: NavigationService? = nil, voiceController: RouteVoiceController? = nil, bottomBanner: ContainerViewController? = nil) {
        self.init()
        self.styles = styles
        self.navigationService = navigationService
        self.voiceController = voiceController
        self.bottomBanner = bottomBanner
    }
    
    /**
     Convienence factory-method for convenient bridging to OBJ-C.
     */
    @objc public class func navigationOptions() -> Self {
        return self.init()
    }
}

