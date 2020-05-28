import UIKit
import MapboxNavigation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    weak var currentAppRootViewController: ViewController?
    
    var window: UIWindow?
    @available(iOS 12.0, *)
    lazy var carPlayManager: CarPlayManager = CarPlayManager()
    
    @available(iOS 12.0, *)
    lazy var carPlaySearchController: CarPlaySearchController = CarPlaySearchController()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if isRunningTests() {
            window!.rootViewController = UIViewController()
        }
        #if false
        if CommandLine.arguments.contains("enable-ui-testing") {
            if let viewController = (window?.rootViewController as? UINavigationController)?.visibleViewController as? ViewController {
                viewController.testSKUTokens()
            }
        }
        #endif
        
        return true
    }

    private func isRunningTests() -> Bool {
        return NSClassFromString("XCTestCase") != nil
    }
}
