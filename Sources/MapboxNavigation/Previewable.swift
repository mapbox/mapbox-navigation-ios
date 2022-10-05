import UIKit

protocol Previewable: UIViewController {
    
    var navigationView: NavigationView { get }
    
    var cameraMode: Preview.CameraMode { get }
    
    var topBanners: Stack<BannerPreviewing> { get }
    
    var bottomBanners: Stack<BannerPreviewing> { get }
    
    func popBanner(_ position: Banner.Position, animated: Bool) -> BannerPreviewing?
    
    func pushBanner(_ banner: BannerPreviewing, animated: Bool)
}
