import CoreGraphics
import MapboxCoreNavigation

// :nodoc:
public protocol BannerContainerViewDelegate: AnyObject, UnimplementedLogging {
    
    func bannerContainerView(_ bannerContainerView: BannerContainerView,
                             stateWillChangeTo state: BannerContainerView.State)
    
    func bannerContainerView(_ bannerContainerView: BannerContainerView,
                             stateDidChangeTo state: BannerContainerView.State)
    
    func bannerContainerView(_ bannerContainerView: BannerContainerView,
                             didExpandTo fraction: CGFloat)
}

// :nodoc:
public extension BannerContainerViewDelegate {
    
    func bannerContainerView(_ bannerContainerView: BannerContainerView,
                             stateWillChangeTo state: BannerContainerView.State) {
        logUnimplemented(protocolType: BannerContainerViewDelegate.self, level: .debug)
    }
    
    func bannerContainerView(_ bannerContainerView: BannerContainerView,
                             stateDidChangeTo state: BannerContainerView.State) {
        logUnimplemented(protocolType: BannerContainerViewDelegate.self, level: .debug)
    }
    
    func bannerContainerView(_ bannerContainerView: BannerContainerView,
                             didExpandTo fraction: CGFloat) {
        logUnimplemented(protocolType: BannerContainerViewDelegate.self, level: .debug)
    }
}
