import UIKit

extension NavigationView {
    
    func setupConstraints() {
        NSLayoutConstraint.deactivate(regularConstraints)
        regularConstraints = []
        setupRegularConstraints(&regularConstraints)
        
        NSLayoutConstraint.deactivate(compactConstraints)
        compactConstraints = []
        setupCompactConstraints(&compactConstraints)
        
        reinstallConstraints()
    }
    
    func setupRegularConstraints(_ layoutConstraints: inout [NSLayoutConstraint]) {
        let navigationMapViewConstraints = [
            navigationMapView.topAnchor.constraint(equalTo: topAnchor),
            navigationMapView.leadingAnchor.constraint(equalTo: leadingAnchor),
            navigationMapView.bottomAnchor.constraint(equalTo: bottomAnchor),
            navigationMapView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ]
        
        layoutConstraints.append(contentsOf: navigationMapViewConstraints)
        
        let topBannerContainerViewLeadingConstraint = topBannerContainerView.leadingAnchor.constraint(equalTo: leadingAnchor)
        let topBannerContainerViewTrailingConstraint = topBannerContainerView.trailingAnchor.constraint(equalTo: trailingAnchor)
        let topBannerContainerViewTopConstraint = topBannerContainerView.topAnchor.constraint(equalTo: topAnchor)
        
        let topBannerConstraints = [
            topBannerContainerViewLeadingConstraint,
            topBannerContainerViewTrailingConstraint,
            topBannerContainerViewTopConstraint
        ]
        
        layoutConstraints.append(contentsOf: topBannerConstraints)
        
        if let floatingStackViewLayoutGuide = floatingStackViewLayoutGuide {
            let floatingStackViewLayoutConstraints = floatingStackViewLayoutGuide.layoutConstraints(for: floatingStackView)
            layoutConstraints.append(contentsOf: floatingStackViewLayoutConstraints)
        } else {
            let floatingStackViewTopConstraint = floatingStackView.topAnchor.constraint(equalTo: topBannerContainerView.bottomAnchor,
                                                                                        constant: 10)
            
            layoutConstraints.append(floatingStackViewTopConstraint)
            
            switch floatingButtonsPosition {
            case .topLeading:
                let floatingStackViewLeadingConstraint = floatingStackView.leadingAnchor.constraint(equalTo: safeLeadingAnchor,
                                                                                                    constant: 10)
                
                layoutConstraints.append(floatingStackViewLeadingConstraint)
            case .topTrailing:
                let floatingStackViewLeadingContraint: NSLayoutConstraint
                if UIApplication.shared.statusBarOrientation == .landscapeRight {
                    floatingStackViewLeadingContraint = floatingStackView.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                                                                    constant: -10)
                } else {
                    floatingStackViewLeadingContraint = floatingStackView.trailingAnchor.constraint(equalTo: safeTrailingAnchor,
                                                                                                    constant: -10)
                }
                
                layoutConstraints.append(floatingStackViewLeadingContraint)
            }
        }

        let bottomBannerContainerViewTrailingConstraint = bottomBannerContainerView.trailingAnchor.constraint(equalTo: trailingAnchor)
        let bottomBannerContainerViewLeadingConstraint = bottomBannerContainerView.leadingAnchor.constraint(equalTo: leadingAnchor)

        let bottomBannerConstraints = [
            bottomBannerContainerViewTrailingConstraint,
            bottomBannerContainerViewLeadingConstraint
        ]
        
        layoutConstraints.append(contentsOf: bottomBannerConstraints)
        
        let resumeButtonLeadingConstraint = resumeButton.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                                                  constant: 10)
        let resumeButtonBottomConstraint = resumeButton.bottomAnchor.constraint(equalTo: bottomBannerContainerView.topAnchor,
                                                                                constant: -10)
        
        let resumeButtonConstraints = [
            resumeButtonLeadingConstraint,
            resumeButtonBottomConstraint
        ]
        
        layoutConstraints.append(contentsOf: resumeButtonConstraints)
        
        let wayNameViewConstraints: [NSLayoutConstraint]
        if let wayNameViewLayoutGuide = wayNameViewLayoutGuide {
            wayNameViewConstraints = wayNameViewLayoutGuide.layoutConstraints(for: wayNameView)
        } else {
            let wayNameViewCenterXConstraint = wayNameView.centerXAnchor.constraint(lessThanOrEqualTo: bottomBannerContainerView.centerXAnchor)
            let wayNameViewBottomConstraint = wayNameView.bottomAnchor.constraint(equalTo: bottomBannerContainerView.topAnchor,
                                                                                  constant: -10)
            let wayNameViewWidthConstraint = wayNameView.widthAnchor.constraint(lessThanOrEqualTo: bottomBannerContainerView.widthAnchor)
            let wayNameViewHeightConstraint = wayNameView.heightAnchor.constraint(equalToConstant: 40.0)
            
            wayNameViewConstraints = [
                wayNameViewCenterXConstraint,
                wayNameViewBottomConstraint,
                wayNameViewWidthConstraint,
                wayNameViewHeightConstraint
            ]
        }
        
        layoutConstraints.append(contentsOf: wayNameViewConstraints)
        
        let speedLimitViewConstraints: [NSLayoutConstraint]
        if let speedLimitViewLayoutGuide = speedLimitViewLayoutGuide {
            speedLimitViewConstraints = speedLimitViewLayoutGuide.layoutConstraints(for: speedLimitView)
        } else {
            let speedLimitViewTopContraint = speedLimitView.topAnchor.constraint(equalTo: topBannerContainerView.bottomAnchor,
                                                                                 constant: 10)
            let speedLimitViewWidthContraint = speedLimitView.widthAnchor.constraint(equalToConstant: FloatingButton.buttonSize.width)
            let speedLimitViewHeightContraint = speedLimitView.heightAnchor.constraint(equalToConstant: FloatingButton.buttonSize.height)
            
            var defaultSpeedLimitViewConstraints = [
                speedLimitViewTopContraint,
                speedLimitViewWidthContraint,
                speedLimitViewHeightContraint
            ]
            
            switch floatingButtonsPosition {
            case .topLeading:
                let speedLimitViewTrailingConstraint: NSLayoutConstraint
                if UIApplication.shared.statusBarOrientation == .landscapeRight {
                    speedLimitViewTrailingConstraint = speedLimitView.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                                                                constant: -10)
                } else {
                    speedLimitViewTrailingConstraint = speedLimitView.trailingAnchor.constraint(equalTo: safeTrailingAnchor,
                                                                                                constant: -10)
                }
                
                defaultSpeedLimitViewConstraints.append(speedLimitViewTrailingConstraint)
            case .topTrailing:
                let speedLimitViewLeadingContraint = speedLimitView.leadingAnchor.constraint(equalTo: safeLeadingAnchor,
                                                                                             constant: 10)
                
                defaultSpeedLimitViewConstraints.append(speedLimitViewLeadingContraint)
            }
            
            speedLimitViewConstraints = defaultSpeedLimitViewConstraints
        }
        
        layoutConstraints.append(contentsOf: speedLimitViewConstraints)
    }
    
    func setupCompactConstraints(_ layoutConstraints: inout [NSLayoutConstraint]) {
        let navigationMapViewConstraints = [
            navigationMapView.topAnchor.constraint(equalTo: topAnchor),
            navigationMapView.leadingAnchor.constraint(equalTo: leadingAnchor),
            navigationMapView.bottomAnchor.constraint(equalTo: bottomAnchor),
            navigationMapView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ]
        
        layoutConstraints.append(contentsOf: navigationMapViewConstraints)
        
        let topBannerContainerViewLeadingConstraint = topBannerContainerView.leadingAnchor.constraint(equalTo: leadingAnchor)
        let topBannerContainerViewTrailingConstraint = topBannerContainerView.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                                                                        constant: -UIScreen.main.bounds.width * 0.6)
        let topBannerContainerViewTopConstraint = topBannerContainerView.topAnchor.constraint(equalTo: topAnchor)
        
        let topBannerConstraints = [
            topBannerContainerViewLeadingConstraint,
            topBannerContainerViewTrailingConstraint,
            topBannerContainerViewTopConstraint
        ]
        
        layoutConstraints.append(contentsOf: topBannerConstraints)
        
        let floatingStackViewTopConstraint = floatingStackView.topAnchor.constraint(equalTo: safeTopAnchor,
                                                                                    constant: 10)
        
        layoutConstraints.append(floatingStackViewTopConstraint)
        
        if let floatingStackViewLayoutGuide = floatingStackViewLayoutGuide {
            let floatingStackViewLayoutConstraints = floatingStackViewLayoutGuide.layoutConstraints(for: floatingStackView)
            layoutConstraints.append(contentsOf: floatingStackViewLayoutConstraints)
        } else {
            switch floatingButtonsPosition {
            case .topLeading:
                let floatingStackViewLeadingConstraint = floatingStackView.leadingAnchor.constraint(equalTo: topBannerContainerView.trailingAnchor,
                                                                                                    constant: 10)
                
                layoutConstraints.append(floatingStackViewLeadingConstraint)
            case .topTrailing:
                let floatingStackViewTrailingConstraint: NSLayoutConstraint
                // Device is in landscape mode and notch (if present) is located on the left side.
                if UIApplication.shared.statusBarOrientation == .landscapeRight {
                    if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
                        // Language with right-to-left interface layout is used.
                        floatingStackViewTrailingConstraint = floatingStackView.trailingAnchor.constraint(equalTo: safeTrailingAnchor,
                                                                                                          constant: -10)
                    } else {
                        // Language with left-to-right interface layout is used.
                        floatingStackViewTrailingConstraint = floatingStackView.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                                                                          constant: -10)
                    }
                } else {
                    if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
                        floatingStackViewTrailingConstraint = floatingStackView.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                                                                          constant: -10)
                    } else {
                        floatingStackViewTrailingConstraint = floatingStackView.trailingAnchor.constraint(equalTo: safeTrailingAnchor,
                                                                                                          constant: -10)
                    }
                }
                
                layoutConstraints.append(floatingStackViewTrailingConstraint)
            }
        }
        
        let bottomBannerContainerViewTrailingConstraint = bottomBannerContainerView.trailingAnchor.constraint(equalTo: topBannerContainerView.trailingAnchor)
        let bottomBannerContainerViewLeadingConstraint = bottomBannerContainerView.leadingAnchor.constraint(equalTo: leadingAnchor)
        
        let bottomBannerConstraints = [
            bottomBannerContainerViewTrailingConstraint,
            bottomBannerContainerViewLeadingConstraint
        ]
        
        layoutConstraints.append(contentsOf: bottomBannerConstraints)
        
        let resumeButtonLeadingConstraint: NSLayoutConstraint
        if UIApplication.shared.statusBarOrientation == .landscapeRight {
            if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
                resumeButtonLeadingConstraint = resumeButton.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                                                      constant: 10)
            } else {
                resumeButtonLeadingConstraint = resumeButton.leadingAnchor.constraint(equalTo: safeLeadingAnchor,
                                                                                      constant: 10)
            }
        } else {
            if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
                resumeButtonLeadingConstraint = resumeButton.leadingAnchor.constraint(equalTo: safeLeadingAnchor,
                                                                                      constant: 10)
            } else {
                resumeButtonLeadingConstraint = resumeButton.leadingAnchor.constraint(equalTo: leadingAnchor,
                                                                                      constant: 10)
            }
        }
        
        let resumeButtonBottomConstraint = resumeButton.bottomAnchor.constraint(equalTo: bottomBannerContainerView.topAnchor,
                                                                                constant: -10)
        
        let resumeButtonConstraints = [
            resumeButtonLeadingConstraint,
            resumeButtonBottomConstraint
        ]
        
        layoutConstraints.append(contentsOf: resumeButtonConstraints)
        
        let wayNameViewConstraints: [NSLayoutConstraint]
        if let wayNameViewLayoutGuide = wayNameViewLayoutGuide {
            wayNameViewConstraints = wayNameViewLayoutGuide.layoutConstraints(for: wayNameView)
        } else {
            let wayNameViewCenterXConstraint = wayNameView.centerXAnchor.constraint(lessThanOrEqualTo: bottomBannerContainerView.centerXAnchor)
            let wayNameViewBottomConstraint = wayNameView.bottomAnchor.constraint(equalTo: bottomBannerContainerView.topAnchor,
                                                                                  constant: -10)
            let wayNameViewWidthConstraint = wayNameView.widthAnchor.constraint(lessThanOrEqualTo: bottomBannerContainerView.widthAnchor)
            let wayNameViewHeightConstraint = wayNameView.heightAnchor.constraint(equalToConstant: 40.0)
            
            wayNameViewConstraints = [
                wayNameViewCenterXConstraint,
                wayNameViewBottomConstraint,
                wayNameViewWidthConstraint,
                wayNameViewHeightConstraint
            ]
        }
        
        layoutConstraints.append(contentsOf: wayNameViewConstraints)
        
        let speedLimitViewConstraints: [NSLayoutConstraint]
        if let speedLimitViewLayoutGuide = speedLimitViewLayoutGuide {
            speedLimitViewConstraints = speedLimitViewLayoutGuide.layoutConstraints(for: speedLimitView)
        } else {
            let speedLimitViewTopContraint = speedLimitView.topAnchor.constraint(equalTo: safeTopAnchor,
                                                                                 constant: 10)
            let speedLimitViewWidthContraint = speedLimitView.widthAnchor.constraint(equalToConstant: FloatingButton.buttonSize.width)
            let speedLimitViewHeightContraint = speedLimitView.heightAnchor.constraint(equalToConstant: FloatingButton.buttonSize.height)
            
            var defaultSpeedLimitViewConstraints = [
                speedLimitViewTopContraint,
                speedLimitViewWidthContraint,
                speedLimitViewHeightContraint
            ]
            
            switch floatingButtonsPosition {
            case .topLeading:
                let speedLimitViewTrailingConstraint: NSLayoutConstraint
                if UIApplication.shared.statusBarOrientation == .landscapeRight {
                    speedLimitViewTrailingConstraint = speedLimitView.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                                                                constant: -10)
                } else {
                    speedLimitViewTrailingConstraint = speedLimitView.trailingAnchor.constraint(equalTo: safeTrailingAnchor,
                                                                                                constant: -10)
                }
                
                defaultSpeedLimitViewConstraints.append(speedLimitViewTrailingConstraint)
            case .topTrailing:
                let speedLimitViewLeadingContraint = speedLimitView.leadingAnchor.constraint(equalTo: topBannerContainerView.trailingAnchor,
                                                                                             constant: 10)
                
                defaultSpeedLimitViewConstraints.append(speedLimitViewLeadingContraint)
            }
            
            speedLimitViewConstraints = defaultSpeedLimitViewConstraints
        }
        
        layoutConstraints.append(contentsOf: speedLimitViewConstraints)
    }
    
    func reinstallConstraints() {
        compactConstraints.forEach({ $0.isActive = traitCollection.verticalSizeClass == .compact })
        regularConstraints.forEach({ $0.isActive = traitCollection.verticalSizeClass == .regular })
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if previousTraitCollection == traitCollection { return }
        
        setupConstraints()
        
        if previousTraitCollection?.verticalSizeClass != traitCollection.verticalSizeClass {
            setupBottomBannerContainerViewHeightLayoutConstraints()
        }
    }
    
    /**
     Sets top banner container view height constraints.
     */
    func setupTopBannerContainerViewHeightLayoutConstraints(_ height: CGFloat? = nil) {
        NSLayoutConstraint.deactivate(topBannerContainerViewLayoutConstraints)
        
        // In case if top banner height was set - use it. Otherwise use default height
        // (height of top safe area insets).
        let topBannerContainerViewHeight: CGFloat
        if let height = height {
            topBannerContainerViewHeight = height + safeAreaInsets.top
        } else {
            topBannerContainerViewHeight = safeAreaInsets.top
        }
        
        topBannerContainerViewLayoutConstraints = [
            topBannerContainerView.heightAnchor.constraint(equalToConstant: topBannerContainerViewHeight)
        ]
        
        NSLayoutConstraint.activate(topBannerContainerViewLayoutConstraints)
    }
    
    /**
     Sets bottom banner container height view constraints for portrait and landscape modes. In landscape mode
     height of bottom banner container view is lower than in portrait.
     */
    func setupBottomBannerContainerViewHeightLayoutConstraints(_ height: CGFloat? = nil) {
        NSLayoutConstraint.deactivate(bottomBannerContainerViewLayoutConstraints)
        
        // In case if bottom banner height was set - use it. Otherwise use default height for
        // specific trait collection.
        let bottomBannerContainerViewHeight: CGFloat
        if let height = height {
            bottomBannerContainerViewHeight = height + safeAreaInsets.bottom
        } else {
            if traitCollection.verticalSizeClass == .regular {
                bottomBannerContainerViewHeight = 80.0 + safeAreaInsets.bottom
            } else {
                bottomBannerContainerViewHeight = 60.0 + safeAreaInsets.bottom
            }
        }
        
        bottomBannerContainerViewLayoutConstraints = [
            bottomBannerContainerView.heightAnchor.constraint(equalToConstant: bottomBannerContainerViewHeight)
        ]
        
        NSLayoutConstraint.activate(bottomBannerContainerViewLayoutConstraints)
    }
    
    func setupEndOfRouteConstraints() {
        guard let endOfRouteView = endOfRouteView,
              let endOfRouteShowConstraint = endOfRouteShowConstraint,
              let endOfRouteHeightConstraint = endOfRouteHeightConstraint else { return }
        
        NSLayoutConstraint.deactivate(endOfRouteViewLayoutConstraints)
                                
        let endOfRouteLeadingConstraint  = endOfRouteView.leadingAnchor.constraint(equalTo: bottomBannerContainerView.leadingAnchor)
        
        let endOfRouteTrailingConstraint  = endOfRouteView.trailingAnchor.constraint(equalTo: bottomBannerContainerView.trailingAnchor)
        
        endOfRouteViewLayoutConstraints = [
            endOfRouteShowConstraint,
            endOfRouteHeightConstraint,
            endOfRouteLeadingConstraint,
            endOfRouteTrailingConstraint
        ]
        
        NSLayoutConstraint.activate(endOfRouteViewLayoutConstraints)
    }
}
