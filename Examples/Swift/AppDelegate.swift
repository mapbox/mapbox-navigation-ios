import UIKit
import MapboxNavigation
import CarPlay

/**
 This example application delegate implementation is used in both our "Example-Swift" and our "Example-CarPlay" example apps.

 In order to run the "Example-CarPlay" example app with CarPlay functionality enabled, one must first obtain a CarPlay entitlement from Apple.

 Once the entitlement has been obtained and loaded into your ADC account:
  - Create a provisioning profile which includes that entitlement
  - Download and select that provisioning profile for the "Example-CarPlay" example app 
  - Be sure to select an iOS simulator or device running iOS 12 or greater
 **/
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, CPApplicationDelegate {

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

    // MARK: CPApplicationDelegate

    @available(iOS 12.0, *)
    func application(_ application: UIApplication, didConnectCarInterfaceController interfaceController: CPInterfaceController, to window: CPWindow) {

        CarPlayManager.shared.application(application, didConnectCarInterfaceController: interfaceController, to: window)

        let mapTemplate = CPMapTemplate()
        interfaceController.setRootTemplate(mapTemplate, animated: false)
        let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "mainMap") as! ViewController
        window.rootViewController = viewController
    }

    @available(iOS 12.0, *)
    func application(_ application: UIApplication, didDisconnectCarInterfaceController interfaceController: CPInterfaceController, from window: CPWindow) {
        CarPlayManager.shared.application(application, didDisconnectCarInterfaceController: interfaceController, from: window)
    }

}
