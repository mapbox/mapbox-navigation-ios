import CoreGraphics
import MapboxNavigationCore

@_documentation(visibility: internal)
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
