import Foundation
import MapboxCoreNavigation

/**
 Customization options for the turn-by-turn navigation user experience in a `NavigationViewController`.
 
 A navigation options object is where you place customized components that the navigation view controller uses during its lifetime, such as styles or voice controllers. You would likely use this class if you need to specify a Mapbox access token programmatically instead of in the Info.plist file.
 
 - note: `NavigationOptions` is designed to be used with the `NavigationViewController` class to customize the user experience. To specify criteria when calculating routes, use the `NavigationRouteOptions` class. To modify user preferences that persist across navigation sessions, use the `NavigationSettings` class.
 */
open class NavigationOptions: NavigationCustomizable {
    /**
     The styles that the view controller’s internal `StyleManager` object can select from for display.
     
     If this property is set to `nil`, a `DayStyle` and a `NightStyle` are created to be used as the view controller’s styles. This property is set to `nil` by default.
     */
    open var styles: [Style]? = nil
    
    /**
     The navigation service that manages navigation along the route.
     */
    open var navigationService: NavigationService?
    
    /**
     The voice controller that manages the delivery of voice instructions during navigation.
     */
    open var voiceController: RouteVoiceController?
    
    /**
     The view controller to embed into the top section of the UI.
     
     If this property is set to `nil`, a `TopBannerViewController` is created and embedded in the UI. This property is set to `nil` by default.
     */
    open var topBanner: ContainerViewController?
    
    /**
     The view controller to embed into the bottom section of the UI.
     
     If this property is set to `nil`, a `BottomBannerViewController` is created and embedded in the UI. This property is set to `nil` by default.
     */
    open var bottomBanner: ContainerViewController?
    
    /**
     Version of tiles downloaded via Offline Service.
     */
    open var tilesVersion: String? = nil
    
    // This makes the compiler happy.
    required public init() {
        // do nothing
    }
    
    /**
     Initializes an object that configures a `NavigationViewController`.
     
     - parameter styles: The user interface styles that are available for display.
     - parameter navigationService: The navigation service that coordinates the view controller’s nonvisual components, tracking the user’s location as they proceed along the route.
     - parameter voiceController: The voice controller that vocalizes spoken instructions along the route at the appropriate times.
     - parameter topBanner: The container view controller that presents the top banner.
     - parameter bottomBanner: The container view controller that presents the bottom banner.
     - parameter tilesVersion: Version of tiles downloaded via Offline Service.
     */
    public convenience init(styles: [Style]? = nil,
                            navigationService: NavigationService? = nil,
                            voiceController: RouteVoiceController? = nil,
                            topBanner: ContainerViewController? = nil,
                            bottomBanner: ContainerViewController? = nil,
                            tilesVersion: String? = nil) {
        self.init()
        self.styles = styles
        self.navigationService = navigationService
        self.voiceController = voiceController
        self.topBanner = topBanner
        self.bottomBanner = bottomBanner
        self.tilesVersion = tilesVersion
    }
    
    /**
     Convienence factory-method for convenient bridging to Objective-C.
     */
    public class func navigationOptions() -> Self {
        return self.init()
    }
}

