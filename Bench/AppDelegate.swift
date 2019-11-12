import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        if isRunningTests() {
            window?.rootViewController = UIViewController()
        } else {
            let viewController = BenchViewController()
            window?.rootViewController = UINavigationController(rootViewController: viewController)
            window?.makeKeyAndVisible()
        }
        
        return true
    }
    
    private func isRunningTests() -> Bool {
        return NSClassFromString("XCTestCase") != nil
    }
}

