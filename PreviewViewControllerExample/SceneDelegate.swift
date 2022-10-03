import UIKit
import CoreLocation
import MapboxNavigation
import MapboxCoreNavigation
import MapboxDirections
import MapboxMaps

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    
    var routeResponse: RouteResponse?
    
    var routeIndex: Int = 0
    
    var coordinates: [CLLocationCoordinate2D] = []
    
    var previewViewController: PreviewViewController!
    
    var useCustomBannerViews = false
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)
        
        let previewOptions: PreviewOptions
        if useCustomBannerViews {
            previewOptions = PreviewOptions(styles: [PreviewDayStyle(), PreviewNightStyle()])
        } else {
            previewOptions = PreviewOptions()
        }
        
        previewViewController = PreviewViewController(previewOptions)
        previewViewController.delegate = self
        window?.rootViewController = previewViewController
        window?.makeKeyAndVisible()
    }
}
