import UIKit
import MapboxNavigation
import MapboxCoreNavigation
import MapboxDirections

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, NavigationViewControllerDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        startNavigation()
        self.window?.makeKeyAndVisible()
        return true
    }
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        startNavigation()
    }
    
    func startNavigation() {
        // From URL
        // let url = URL(string: "<#https://api.mapbox.com/directions/v5/mapbox.json?...#>")!
        // let route = Fixture.route(from: url)
        
        // Bundled Route
        let route = Fixture.route(from: "downtown-sf")
        
        let locationManager = SimulatedLocationManager(route: route)
        let controller = NavigationViewController(for: route, directions: Directions.shared, styles: nil, locationManager: locationManager)
        controller.delegate = self
        window?.rootViewController = controller
    }
}
