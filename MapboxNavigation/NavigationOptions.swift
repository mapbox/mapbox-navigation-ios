import Foundation
import MapboxCoreNavigation

/*
    Object representing available options for a Navigation Session.
 */

@objc(MBNavigationOptions)
open class NavigationOptions: NSObject {
    
    /*
     The styles that the view controller’s internal `StyleManager` object can select from for display. Defaults to `[DayStyle(), NightStyle()]`
     */
    @objc public var styles: [Style]? = nil
    
    /*
     The navigation service that manages navigation along the route.
     */
    @objc open var navigationService: NavigationService?
    
    /*
     The voice controller that manages the delivery of voice instructions during navigation.
    */
    @objc public var voiceController: RouteVoiceController?
    
    /*
     The view controlelr to embed into the bottom section of the UI. Defaults to `BottomBannerViewController`.
     */
    @objc public var bottomBanner: ContainerViewController?
    
    @objc public convenience init(styles: [Style]? = nil, navigationService: NavigationService? = nil, voiceController: RouteVoiceController? = nil, bottomBanner: ContainerViewController? = nil) {
        self.init()
        self.styles = styles
        self.navigationService = navigationService
        self.voiceController = voiceController
        self.bottomBanner = bottomBanner
    }
}
