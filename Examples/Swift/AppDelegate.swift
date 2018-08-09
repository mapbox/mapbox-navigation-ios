import UIKit
import MapboxNavigation
#if canImport(CarPlay)
import CarPlay
#endif

/**
 This example application delegate implementation is used in both our "Example-Swift" and our "Example-CarPlay" example apps.

 In order to run the "Example-CarPlay" example app with CarPlay functionality enabled, one must first obtain a CarPlay entitlement from Apple.

 Once the entitlement has been obtained and loaded into your ADC account:
  - Create a provisioning profile which includes the entitlement
  - Download and select the provisioning profile for the "Example-CarPlay" example app
  - Be sure to select an iOS simulator or device running iOS 12 or greater
 **/
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        if isRunningTests() {
            window!.rootViewController = UIViewController()
        }
        return true
    }

    private func isRunningTests() -> Bool {
        return NSClassFromString("XCTestCase") != nil
    }

#if canImport(CarPlay)
    // MARK: Mapbox CarPlay support

    @available(iOS 12.0, *)
    lazy var carPlayManager = {
        return CarPlayManager.shared()
    }()
#endif
}

#if canImport(CarPlay)
extension AppDelegate: CPApplicationDelegate {

    // MARK: CPApplicationDelegate

    @available(iOS 12.0, *)
    func application(_ application: UIApplication, didConnectCarInterfaceController interfaceController: CPInterfaceController, to window: CPWindow) {
        carPlayManager.application(application, didConnectCarInterfaceController: interfaceController, to: window)
    }

    @available(iOS 12.0, *)
    func application(_ application: UIApplication, didDisconnectCarInterfaceController interfaceController: CPInterfaceController, from window: CPWindow) {
        carPlayManager.application(application, didDisconnectCarInterfaceController: interfaceController, from: window)
    }
}
#endif
