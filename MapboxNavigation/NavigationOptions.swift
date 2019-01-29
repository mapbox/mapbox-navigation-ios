import Foundation
import MapboxCoreNavigation

class NavigationOptions {
    lazy var styles: [Style] = [DayStyle(), NightStyle()]
    
    var navigationService: NavigationService?
    
    var voiceController: RouteVoiceController?
    
    var bottomBanner: UIViewController?
}
