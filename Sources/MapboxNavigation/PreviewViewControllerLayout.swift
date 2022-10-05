import UIKit

extension PreviewViewController {
    
    func setupConstraints() {
        // TODO: Verify that back button is shown correctly for right-to-left languages.
        let backButtonLayoutConstraints = [
            backButton.widthAnchor.constraint(equalToConstant: 110.0),
            backButton.heightAnchor.constraint(equalToConstant: 50.0),
            backButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                                constant: 10.0),
            backButton.topAnchor.constraint(equalTo: navigationView.topBannerContainerView.bottomAnchor,
                                            constant: 10.0)
        ]
        
        NSLayoutConstraint.activate(backButtonLayoutConstraints)
        
        // Layout guide is used to modify default position of the `SpeedLimitView`.
        let speedLimitViewLayoutGuide = UILayoutGuide()
        navigationView.addLayoutGuide(speedLimitViewLayoutGuide)
        
        let speedLimitViewLayoutGuideLayoutConstraints = [
            speedLimitViewLayoutGuide.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor,
                                                           constant: 10.0),
            speedLimitViewLayoutGuide.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                                                               constant: 10.0),
            speedLimitViewLayoutGuide.widthAnchor.constraint(equalToConstant: 50.0),
            speedLimitViewLayoutGuide.heightAnchor.constraint(equalToConstant: 50.0)
        ]
        
        NSLayoutConstraint.activate(speedLimitViewLayoutGuideLayoutConstraints)
        navigationView.speedLimitViewLayoutGuide = speedLimitViewLayoutGuide
        
        // Layout guide is used to modify default position of the `WayNameView`.
        let wayNameViewLayoutGuide = UILayoutGuide()
        navigationView.addLayoutGuide(wayNameViewLayoutGuide)
        
        let wayNameViewLayoutGuideLayoutContraints = [
            wayNameViewLayoutGuide.bottomAnchor.constraint(equalTo: navigationView.safeBottomAnchor,
                                                           constant: -60.0),
            wayNameViewLayoutGuide.centerXAnchor.constraint(equalTo: navigationView.safeCenterXAnchor),
            wayNameViewLayoutGuide.widthAnchor.constraint(lessThanOrEqualTo: navigationView.safeWidthAnchor,
                                                          multiplier: 0.95),
            wayNameViewLayoutGuide.heightAnchor.constraint(equalToConstant: 40.0)
        ]
        
        NSLayoutConstraint.activate(wayNameViewLayoutGuideLayoutContraints)
        navigationView.wayNameViewLayoutGuide = wayNameViewLayoutGuide
        
        // Setup floating stack view layout constraints.
        let floatingStackViewLayoutConstraints = [
            navigationView.floatingStackView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor,
                                                                       constant: -10.0)
        ]
        
        NSLayoutConstraint.activate(floatingStackViewLayoutConstraints)
        
        setupBottomBannerContainerViewLayoutConstraints()
        setupTopBannerContainerViewLayoutConstraints()
    }
    
    /**
     Sets bottom banner container view constraints for portrait and landscape modes. In landscape mode
     height of bottom banner container view is lower than in portrait.
     */
    func setupBottomBannerContainerViewLayoutConstraints() {
        NSLayoutConstraint.deactivate(bottomBannerContainerViewLayoutConstraints)
        
        // In case if bottom banner height was set - use it. Otherwise use default height for
        // specific trait collection.
        let bottomBannerContainerViewHeight: CGFloat
        if let height = topmostBottomBanner?.configuration.height {
            bottomBannerContainerViewHeight = height
        } else {
            if traitCollection.verticalSizeClass == .regular {
                bottomBannerContainerViewHeight = 80.0 + view.safeAreaInsets.bottom
            } else {
                bottomBannerContainerViewHeight = 60.0 + view.safeAreaInsets.bottom
            }
        }
        
        bottomBannerContainerViewLayoutConstraints = [
            navigationView.bottomBannerContainerView.heightAnchor.constraint(equalToConstant: bottomBannerContainerViewHeight)
        ]
        
        NSLayoutConstraint.activate(bottomBannerContainerViewLayoutConstraints)
    }
    
    /**
     Sets top banner container view constraints.
     */
    func setupTopBannerContainerViewLayoutConstraints() {
        NSLayoutConstraint.deactivate(topBannerContainerViewLayoutConstraints)
        
        // In case if top banner height was set - use it. Otherwise use default height
        // (height of top safe area insets).
        let topBannerContainerViewHeight: CGFloat
        if let height = topmostTopBanner?.configuration.height {
            topBannerContainerViewHeight = height
        } else {
            topBannerContainerViewHeight = view.safeAreaInsets.top
        }
        
        topBannerContainerViewLayoutConstraints = [
            navigationView.topBannerContainerView.heightAnchor.constraint(equalToConstant: topBannerContainerViewHeight)
        ]
        
        NSLayoutConstraint.activate(topBannerContainerViewLayoutConstraints)
    }
}
