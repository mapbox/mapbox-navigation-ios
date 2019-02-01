import Foundation
import MapboxCoreNavigation

/*
    Options that are available to customize the NavigationViewController.
    - note: Use this class if you wish to customize the internals of the navigation experience, such as a custom style or voice controller.
 */

@objc(MBNavigationOptions)
open class NavigationOptions: NSObject, NavigationCustomizable {
    
    /**
     The styles that the view controller’s internal `StyleManager` object can select from for display. Defaults to `[DayStyle(), NightStyle()]`
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
     The view controller to embed into the bottom section of the UI. Defaults to `BottomBannerViewController`.
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
    class func navigationOptions() -> Self {
        return self.init()
    }
}

