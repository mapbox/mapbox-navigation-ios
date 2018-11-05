import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        let viewController = BenchViewController()
        
        window?.rootViewController = UINavigationController(rootViewController: viewController)
        
        window?.makeKeyAndVisible()
        
        return true
    }
}

