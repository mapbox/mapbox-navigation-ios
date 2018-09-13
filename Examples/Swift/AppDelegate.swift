import UIKit
import MapboxNavigation


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    #if canImport(CarPlay)
    var simulatesLocationsInCarPlay = false
    #endif

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        if isRunningTests() {
            window!.rootViewController = UIViewController()
        }
        return true
    }

    private func isRunningTests() -> Bool {
        return NSClassFromString("XCTestCase") != nil
    }
}

