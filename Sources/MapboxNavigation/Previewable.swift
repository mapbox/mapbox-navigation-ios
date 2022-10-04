import UIKit

protocol Previewable: UIViewController {
    
    var navigationView: NavigationView { get }
    
    var cameraMode: Preview.CameraMode { get }
    
    var state: Preview.State { get }
    
    var topBanners: Stack<BannerPreviewing> { get }
    
    var bottomBanners: Stack<BannerPreviewing> { get }
    
    func popBanner(_ position: Banner.Position) -> BannerPreviewing?
    
    func pushBanner(_ banner: BannerPreviewing)
}
