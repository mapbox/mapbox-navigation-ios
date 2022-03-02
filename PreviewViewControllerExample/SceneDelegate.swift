import UIKit
import MapboxNavigation

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        let previewViewController = PreviewViewController()
        window?.rootViewController = previewViewController
        window?.makeKeyAndVisible()
    }
}
