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
        
        listMapboxFrameworks()
        
        return true
    }

    private func isRunningTests() -> Bool {
        return NSClassFromString("XCTestCase") != nil
    }
    
    private func listMapboxFrameworks() {
        NSLog("Versions of linked Mapbox frameworks:")
        
        for framework in Bundle.allFrameworks {
            if let bundleIdentifier = framework.bundleIdentifier, bundleIdentifier.contains("mapbox") {
                let version = "CFBundleShortVersionString"
                NSLog("\(bundleIdentifier): \(framework.infoDictionary?[version] ?? "Unknown version")")
            }
        }
    }
}
