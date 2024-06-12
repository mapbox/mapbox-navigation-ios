import CoreGraphics
import MapboxNavigationCore

// :nodoc:
public protocol BannerContainerViewDelegate: AnyObject, UnimplementedLogging {
    func bannerContainerView(
        _ bannerContainerView: BannerContainerView,
        stateWillChangeTo state: BannerContainerView.State
    )

    func bannerContainerView(
        _ bannerContainerView: BannerContainerView,
        stateDidChangeTo state: BannerContainerView.State
    )

    func bannerContainerView(
        _ bannerContainerView: BannerContainerView,
        didExpandTo fraction: CGFloat
    )
}

// :nodoc:
extension BannerContainerViewDelegate {
    public func bannerContainerView(
        _ bannerContainerView: BannerContainerView,
        stateWillChangeTo state: BannerContainerView.State
    ) {
        logUnimplemented(protocolType: BannerContainerViewDelegate.self, level: .debug)
    }

    public func bannerContainerView(
        _ bannerContainerView: BannerContainerView,
        stateDidChangeTo state: BannerContainerView.State
    ) {
        logUnimplemented(protocolType: BannerContainerViewDelegate.self, level: .debug)
    }

    public func bannerContainerView(
        _ bannerContainerView: BannerContainerView,
        didExpandTo fraction: CGFloat
    ) {
        logUnimplemented(protocolType: BannerContainerViewDelegate.self, level: .debug)
    }
}
