import UIKit

protocol BannerPresentation: UIViewController {
    
    var navigationView: NavigationView { get }
    
    var bannerPresentationDelegate: BannerPresentationDelegate? { get set }
    
    var topBanners: Stack<Banner> { get set }
    
    var bottomBanners: Stack<Banner> { get set }
    
    func topBanner(at position: BannerPosition) -> Banner?
    
    func popAllExceptFirstBanner(at position: BannerPosition,
                                 animated: Bool,
                                 duration: TimeInterval,
                                 animations: (() -> Void)?,
                                 completion: (() -> Void)?)
    
    func popBanner(at position: BannerPosition,
                   animated: Bool,
                   duration: TimeInterval,
                   animations: (() -> Void)?,
                   completion: (() -> Void)?,
                   popAllExceptFirstBanner: Bool) -> Banner?
    
    func push(_ banner: Banner,
              animated: Bool,
              duration: TimeInterval,
              animations: (() -> Void)?,
              completion: (() -> Void)?)
}

extension BannerPresentation {
    
    var topmostTopBanner: Banner? {
        topBanners.peek()
    }
    
    var topmostBottomBanner: Banner? {
        bottomBanners.peek()
    }
    
    func topBanner(at position: BannerPosition) -> Banner? {
        switch position {
        case .topLeading:
            return topmostTopBanner
        case .bottomLeading:
            return topmostBottomBanner
        }
    }
    
    @discardableResult
    func popBanner(at position: BannerPosition,
                   animated: Bool = true,
                   duration: TimeInterval = 1.0,
                   animations: (() -> Void)? = nil,
                   completion: (() -> Void)? = nil,
                   popAllExceptFirstBanner: Bool = false) -> Banner? {
        let banner: Banner?
        switch position {
        case .topLeading:
            banner = topmostTopBanner
        case .bottomLeading:
            banner = topmostBottomBanner
        }
        
        if let banner = banner {
            bannerPresentationDelegate?.bannerWillDisappear(self, banner: banner)
            
            let bannerDismissalCompletion = { [weak self] in
                guard let self = self else { return }
                
                completion?()
                self.bannerPresentationDelegate?.bannerDidDisappear(self, banner: banner)
            }
            
            switch position {
            case .topLeading:
                let bannerContainerView = navigationView.topBannerContainerView
                
                if popAllExceptFirstBanner {
                    topBanners.popAllExceptFirst()
                } else {
                    topBanners.pop()
                }
                
                if let topBanner = topmostTopBanner {
                    navigationView.topBannerContainerView.hide(animated: animated,
                                                               duration: duration,
                                                               animations: animations,
                                                               completion: { [weak self] _ in
                        guard let self = self else { return }
                        
                        bannerContainerView.subviews.forEach {
                            $0.removeFromSuperview()
                        }
                        
                        self.navigationView.topBannerContainerView.isExpandable = topBanner.bannerConfiguration.isExpandable
                        self.navigationView.topBannerContainerView.expansionOffset = topBanner.bannerConfiguration.expansionOffset
                        
                        self.embed(topBanner, in: bannerContainerView)
                        
                        self.navigationView.setupTopBannerContainerViewHeightLayoutConstraints(topBanner.bannerConfiguration.height)
                        
                        self.navigationView.topBannerContainerView.show(animated: animated,
                                                                        duration: duration,
                                                                        animations: animations,
                                                                        completion: { _ in
                            bannerDismissalCompletion()
                        })
                    })
                } else {
                    navigationView.topBannerContainerView.hide(animated: animated,
                                                               duration: duration,
                                                               animations: animations,
                                                               completion: { _ in
                        bannerContainerView.subviews.forEach {
                            $0.removeFromSuperview()
                        }
                        
                        bannerDismissalCompletion()
                    })
                }
            case .bottomLeading:
                let bannerContainerView = navigationView.bottomBannerContainerView
                
                if popAllExceptFirstBanner {
                    bottomBanners.popAllExceptFirst()
                } else {
                    bottomBanners.pop()
                }
                
                if let bottomBanner = topmostBottomBanner {
                    navigationView.bottomBannerContainerView.hide(animated: animated,
                                                                  duration: duration,
                                                                  animations: animations,
                                                                  completion: { [weak self] _ in
                        guard let self = self else { return }
                        
                        bannerContainerView.subviews.forEach {
                            $0.removeFromSuperview()
                        }
                        
                        self.navigationView.bottomBannerContainerView.isExpandable = bottomBanner.bannerConfiguration.isExpandable
                        self.navigationView.bottomBannerContainerView.expansionOffset = bottomBanner.bannerConfiguration.expansionOffset
                        
                        self.embed(bottomBanner, in: bannerContainerView)
                        
                        self.navigationView.setupBottomBannerContainerViewHeightLayoutConstraints(bottomBanner.bannerConfiguration.height)
                        
                        self.navigationView.bottomBannerContainerView.show(animated: animated,
                                                                           duration: duration,
                                                                           animations: animations,
                                                                           completion: { _ in
                            bannerDismissalCompletion()
                        })
                    })
                } else {
                    navigationView.bottomBannerContainerView.hide(animated: animated,
                                                                  duration: duration,
                                                                  animations: animations,
                                                                  completion: { _ in
                        bannerContainerView.subviews.forEach {
                            $0.removeFromSuperview()
                        }
                        
                        bannerDismissalCompletion()
                    })
                }
            }
            
            return banner
        }
        
        return nil
    }
    
    func popAllExceptFirstBanner(at position: BannerPosition,
                                 animated: Bool,
                                 duration: TimeInterval,
                                 animations: (() -> Void)?,
                                 completion: (() -> Void)?) {
        _ = popBanner(at: position,
                      animated: animated,
                      duration: duration,
                      animations: animations,
                      completion: completion,
                      popAllExceptFirstBanner: true)
    }
    
    func push(_ banner: Banner,
              animated: Bool = true,
              duration: TimeInterval = 1.0,
              animations: (() -> Void)? = nil,
              completion: (() -> Void)? = nil) {
        bannerPresentationDelegate?.bannerWillAppear(self, banner: banner)
        
        let bannerPresentationCompletion = { [weak self] in
            guard let self = self else { return }
            
            completion?()
            self.bannerPresentationDelegate?.bannerDidAppear(self, banner: banner)
        }
        
        let bannerContainerView: UIView
        switch banner.bannerConfiguration.position {
        case .topLeading:
            bannerContainerView = navigationView.topBannerContainerView
            
            let previousTopmostTopBanner = topmostTopBanner
            topBanners.push(banner)
            
            // Update top banner constraints to change its height if needed.
            navigationView.setupTopBannerContainerViewHeightLayoutConstraints(banner.bannerConfiguration.height)
            
            // In case if banner is already shown - hide it and then present another one.
            if let _ = previousTopmostTopBanner {
                navigationView.topBannerContainerView.hide(animated: animated,
                                                           duration: duration,
                                                           animations: animations,
                                                           completion: { [weak self] _ in
                    guard let self = self else { return }
                    
                    bannerContainerView.subviews.forEach {
                        $0.removeFromSuperview()
                    }
                    
                    self.navigationView.topBannerContainerView.isExpandable = banner.bannerConfiguration.isExpandable
                    self.navigationView.topBannerContainerView.expansionOffset = banner.bannerConfiguration.expansionOffset
                    
                    self.embed(banner, in: bannerContainerView)
                    
                    self.navigationView.setupTopBannerContainerViewHeightLayoutConstraints(banner.bannerConfiguration.height)
                    
                    self.navigationView.topBannerContainerView.show(animated: animated,
                                                                    duration: duration,
                                                                    animations: animations,
                                                                    completion: { _ in
                        bannerPresentationCompletion()
                    })
                })
            } else {
                embed(banner, in: bannerContainerView)
                navigationView.setupTopBannerContainerViewHeightLayoutConstraints(banner.bannerConfiguration.height)
                
                navigationView.topBannerContainerView.isExpandable = banner.bannerConfiguration.isExpandable
                navigationView.topBannerContainerView.expansionOffset = banner.bannerConfiguration.expansionOffset
                
                navigationView.topBannerContainerView.show(animated: animated,
                                                           duration: duration,
                                                           animations: animations,
                                                           completion: { _ in
                    bannerPresentationCompletion()
                })
            }
        case .bottomLeading:
            bannerContainerView = navigationView.bottomBannerContainerView
            
            let previousTopmostBottomBanner = topmostBottomBanner
            bottomBanners.push(banner)
            
            // In case if banner is already shown - hide it and then present another one.
            if let _ = previousTopmostBottomBanner {
                navigationView.bottomBannerContainerView.hide(animated: animated,
                                                              duration: duration,
                                                              animations: animations,
                                                              completion: { [weak self] _ in
                    guard let self = self else { return }
                    
                    bannerContainerView.subviews.forEach {
                        $0.removeFromSuperview()
                    }
                    
                    self.navigationView.bottomBannerContainerView.isExpandable = banner.bannerConfiguration.isExpandable
                    self.navigationView.bottomBannerContainerView.expansionOffset = banner.bannerConfiguration.expansionOffset
                    
                    self.embed(banner, in: bannerContainerView)
                    
                    self.navigationView.setupBottomBannerContainerViewHeightLayoutConstraints(banner.bannerConfiguration.height)
                    
                    self.navigationView.bottomBannerContainerView.show(animated: animated,
                                                                       duration: duration,
                                                                       animations: animations,
                                                                       completion: { _ in
                        bannerPresentationCompletion()
                    })
                })
            } else {
                embed(banner, in: bannerContainerView)
                navigationView.setupBottomBannerContainerViewHeightLayoutConstraints(banner.bannerConfiguration.height)
                
                navigationView.bottomBannerContainerView.isExpandable = banner.bannerConfiguration.isExpandable
                navigationView.bottomBannerContainerView.expansionOffset = banner.bannerConfiguration.expansionOffset
                
                navigationView.bottomBannerContainerView.show(animated: animated,
                                                              duration: duration,
                                                              animations: animations,
                                                              completion: { _ in
                    bannerPresentationCompletion()
                })
            }
        }
    }
}
