import UIKit
import MapboxNavigation
import CarPlay

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    weak var currentAppRootViewController: ViewController?
    
    var window: UIWindow?
    @available(iOS 12.0, *)
    lazy var carPlayManager: CarPlayManager = CarPlayManager()
    
    @available(iOS 12.0, *)
    lazy var carPlaySearchController: CarPlaySearchController = CarPlaySearchController()

    @available(iOS 12.0, *)
    lazy var interfaceController: CPInterfaceController? = nil

    @available(iOS 12.0, *)
    lazy var carWindow: CPWindow? = nil

    @available(iOS 12.0, *)
    lazy var sessionConfiguration: CPSessionConfiguration? = nil

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if isRunningTests() {
            if window == nil {
                window = UIWindow(frame: UIScreen.main.bounds)
            }
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

@available(iOS 13.0, *)
extension AppDelegate: UIWindowSceneDelegate {

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {

        if connectingSceneSession.role == .carTemplateApplication {
            return UISceneConfiguration(name: "ExampleCarPlayApplicationConfiguration", sessionRole: connectingSceneSession.role)
        }
        return UISceneConfiguration(name: "ExampleAppConfiguration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {

    }
}
