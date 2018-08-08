import CarPlay

@available(iOS 12.0, *)
@objc(MBCarPlayManager)
public class CarPlayManager: NSObject, CPInterfaceControllerDelegate {
    public fileprivate(set) var interfaceController: CPInterfaceController?
    public fileprivate(set) var carWindow: UIWindow?

    private static var privateShared: CarPlayManager?

    public static func shared() -> CarPlayManager {
        if let shared = privateShared {
            return shared
        }
        let shared = CarPlayManager()
        privateShared = shared
        return shared
    }

    public static func resetSharedInstance() {
        privateShared = nil
    }

    // MARK: CPApplicationDelegate

    public func application(_ application: UIApplication, didConnectCarInterfaceController interfaceController: CPInterfaceController, to window: CPWindow) {
        let mapTemplate = CPMapTemplate()

        //TODO: find image or use built-in style?
        let searchButton: CPBarButton = CPBarButton(type: .text) { button in
            //TODO: push Search Template
        }
        searchButton.title = "Search!"
        mapTemplate.leadingNavigationBarButtons = [searchButton]

        interfaceController.setRootTemplate(mapTemplate, animated: false)
        interfaceController.delegate = self
        self.interfaceController = interfaceController

        let viewController = CarPlayMapViewController()
        window.rootViewController = viewController
        self.carWindow = window
    }

    public func application(_ application: UIApplication, didDisconnectCarInterfaceController interfaceController: CPInterfaceController, from window: CPWindow) {
        self.interfaceController = nil
        carWindow?.isHidden = true
    }
}
