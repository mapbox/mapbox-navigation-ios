import UIKit

protocol BannerPresentation: UIViewController {
    
    var navigationView: NavigationView { get }
    
    var bannerPresentationDelegate: BannerPresentationDelegate? { get set }
    
    var topBanners: Stack<Banner> { get set }
    
    var bottomBanners: Stack<Banner> { get set }
    
    func topBanner(_ position: BannerPosition) -> Banner?
    
    func popBanner(_ position: BannerPosition,
                   animated: Bool,
                   completion: (() -> Void)?) -> Banner?
    
    func push(_ banner: Banner,
              animated: Bool,
              completion: (() -> Void)?)
}

extension BannerPresentation {
    
    var topmostTopBanner: Banner? {
        topBanners.peek()
    }
    
    var topmostBottomBanner: Banner? {
        bottomBanners.peek()
    }
    
    func topBanner(_ position: BannerPosition) -> Banner? {
        switch position {
        case .topLeading:
            return topmostTopBanner
        case .bottomLeading:
            return topmostBottomBanner
        }
    }
    
    @discardableResult  func popBanner(_ position: BannerPosition,
                                       animated: Bool = true,
                                       completion: (() -> Void)? = nil) -> Banner? {
        let banner: Banner?
        switch position {
        case .topLeading:
            banner = topmostTopBanner
        case .bottomLeading:
            banner = topmostBottomBanner
        }
        
        if let banner = banner {
            bannerPresentationDelegate?.bannerWillDisappear(self, banner: banner)
            
            switch position {
            case .topLeading:
                let bannerContainerView = navigationView.topBannerContainerView
                topBanners.pop()
                
                if let topBanner = topmostTopBanner {
                    navigationView.topBannerContainerView.hide(animated: animated,
                                                               completion: { _ in
                        bannerContainerView.subviews.forEach {
                            $0.removeFromSuperview()
                        }
                        
                        self.embed(topBanner, in: bannerContainerView)
                        
                        self.navigationView.topBannerContainerView.show()
                    })
                } else {
                    navigationView.topBannerContainerView.hide(animated: animated,
                                                               completion: { _ in
                        bannerContainerView.subviews.forEach {
                            $0.removeFromSuperview()
                        }
                    })
                }
            case .bottomLeading:
                let bannerContainerView = navigationView.bottomBannerContainerView
                bottomBanners.pop()
                
                if let bottomBanner = topmostBottomBanner {
                    navigationView.bottomBannerContainerView.hide(completion: { _ in
                        bannerContainerView.subviews.forEach {
                            $0.removeFromSuperview()
                        }
                        
                        self.embed(bottomBanner, in: bannerContainerView)
                        
                        self.navigationView.bottomBannerContainerView.show()
                    })
                } else {
                    navigationView.bottomBannerContainerView.hide(completion: { _ in
                        bannerContainerView.subviews.forEach {
                            $0.removeFromSuperview()
                        }
                    })
                }
            }
            
            bannerPresentationDelegate?.bannerDidDisappear(self, banner: banner)
            
            return banner
        }
        
        return nil
    }
    
    func push(_ banner: Banner,
              animated: Bool = true,
              completion: (() -> Void)? = nil) {
        bannerPresentationDelegate?.bannerWillAppear(self, banner: banner)
        
        let bannerContainerView: UIView
        switch banner.bannerConfiguration.position {
        case .topLeading:
            bannerContainerView = navigationView.topBannerContainerView
            
            let previousTopmostTopBanner = topmostTopBanner
            topBanners.push(banner)
            
            // Update top banner constraints to change its height if needed.
            navigationView.setupTopBannerContainerViewHeightLayoutConstraints()
            
            // In case if banner is already shown - hide it and then present another one.
            if let _ = previousTopmostTopBanner {
                navigationView.topBannerContainerView.hide(animated: animated,
                                                           completion: { _ in
                    bannerContainerView.subviews.forEach {
                        $0.removeFromSuperview()
                    }
                    
                    self.embed(banner, in: bannerContainerView)
                    self.navigationView.topBannerContainerView.show()
                })
            } else {
                embed(banner, in: bannerContainerView)
                navigationView.topBannerContainerView.show(animated: animated)
            }
        case .bottomLeading:
            bannerContainerView = navigationView.bottomBannerContainerView
            
            let previousTopmostBottomBanner = topmostBottomBanner
            bottomBanners.push(banner)
            
            navigationView.setupBottomBannerContainerViewHeightLayoutConstraints()
            
            // In case if banner is already shown - hide it and then present another one.
            if let _ = previousTopmostBottomBanner {
                navigationView.bottomBannerContainerView.hide(completion: { _ in
                    bannerContainerView.subviews.forEach {
                        $0.removeFromSuperview()
                    }
                    
                    self.embed(banner, in: bannerContainerView)
                    self.navigationView.bottomBannerContainerView.show()
                })
            } else {
                embed(banner, in: bannerContainerView)
                navigationView.bottomBannerContainerView.show()
            }
        }
        
        bannerPresentationDelegate?.bannerDidAppear(self, banner: banner)
    }
}
