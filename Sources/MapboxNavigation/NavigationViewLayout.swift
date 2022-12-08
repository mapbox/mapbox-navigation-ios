import UIKit

extension NavigationView {
    
    func setupConstraints() {
        if orientation == .landscapeLeft || orientation == .landscapeRight{
            print("!!! landscape left")
            self.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 20, leading: 20, bottom: 20, trailing: 20)
        } else {
            self.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 12, leading: 12, bottom: 12, trailing: 12)
            print("!!! portrait")
        }
        margins = self.layoutMarginsGuide
        
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
        
        let topBannerContainerViewLeadingConstraint: NSLayoutConstraint
        let topBannerContainerViewTrailingConstraint: NSLayoutConstraint
        
        // Device is in landscape mode.
        if orientation == .landscapeRight || orientation == .landscapeLeft {
            topBannerContainerViewLeadingConstraint = topBannerContainerView.leadingAnchor.constraint(equalTo: margins.leadingAnchor)
            topBannerContainerViewTrailingConstraint = topBannerContainerView.trailingAnchor.constraint(equalTo: margins.trailingAnchor)
        } else {
            topBannerContainerViewLeadingConstraint = topBannerContainerView.leadingAnchor.constraint(equalTo: leadingAnchor)
            topBannerContainerViewTrailingConstraint = topBannerContainerView.trailingAnchor.constraint(equalTo: trailingAnchor)
        }
        
        let topBannerContainerViewTopConstraint = topBannerContainerView.topAnchor.constraint(equalTo: margins.topAnchor)
        
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
                                                                                        constant: 12)
            
            layoutConstraints.append(floatingStackViewTopConstraint)
            
            switch floatingButtonsPosition {
            case .topLeading:
                print("!!! top leading regular")
                let floatingStackViewLeadingConstraint = floatingStackView.leadingAnchor.constraint(equalTo: margins.leadingAnchor)
                
                layoutConstraints.append(floatingStackViewLeadingConstraint)
            case .topTrailing:
                print("!!! top trailing regular")
                let floatingStackViewLeadingContraint: NSLayoutConstraint
                if orientation == .landscapeRight {
                    floatingStackViewLeadingContraint = floatingStackView.trailingAnchor.constraint(equalTo: trailingAnchor)
                } else {
                    floatingStackViewLeadingContraint = floatingStackView.trailingAnchor.constraint(equalTo: margins.trailingAnchor)
                }
                
                layoutConstraints.append(floatingStackViewLeadingContraint)
            }
        }
        
        let bottomBannerContainerViewTrailingConstraint: NSLayoutConstraint
        let bottomBannerContainerViewLeadingConstraint: NSLayoutConstraint
        
        // Device is in landscape mode.
        if orientation == .landscapeRight || orientation == .landscapeLeft {
            bottomBannerContainerViewTrailingConstraint = bottomBannerContainerView.trailingAnchor.constraint(equalTo: margins.trailingAnchor)
            bottomBannerContainerViewLeadingConstraint = bottomBannerContainerView.leadingAnchor.constraint(equalTo: margins.leadingAnchor)
        } else {
            bottomBannerContainerViewTrailingConstraint = bottomBannerContainerView.trailingAnchor.constraint(equalTo: trailingAnchor)
            bottomBannerContainerViewLeadingConstraint = bottomBannerContainerView.leadingAnchor.constraint(equalTo: leadingAnchor)
        }

        let bottomBannerConstraints = [
            bottomBannerContainerViewTrailingConstraint,
            bottomBannerContainerViewLeadingConstraint
        ]
        
        layoutConstraints.append(contentsOf: bottomBannerConstraints)
        
        let resumeButtonLeadingConstraint = resumeButton.leadingAnchor.constraint(equalTo: margins.leadingAnchor,
                                                                                  constant: 12)
        let resumeButtonBottomConstraint = resumeButton.bottomAnchor.constraint(equalTo: bottomBannerContainerView.topAnchor,
                                                                                constant: -12)
        
        let resumeButtonConstraints = [
            resumeButtonLeadingConstraint,
            resumeButtonBottomConstraint
        ]
        
        layoutConstraints.append(contentsOf: resumeButtonConstraints)
        
        let wayNameViewConstraints: [NSLayoutConstraint]
        let wayNameViewBottomConstraint: NSLayoutConstraint
        
        if let wayNameViewLayoutGuide = wayNameViewLayoutGuide {
            wayNameViewConstraints = wayNameViewLayoutGuide.layoutConstraints(for: wayNameView)
        } else {
            if orientation == .landscapeLeft || orientation == .landscapeRight {
                wayNameViewBottomConstraint = wayNameView.bottomAnchor.constraint(equalTo: safeBottomAnchor,
                                                                                      constant: -16)

            } else {
                wayNameViewBottomConstraint = wayNameView.bottomAnchor.constraint(equalTo: bottomBannerContainerView.topAnchor,
                                                                                          constant: -12)
            }
            let wayNameViewCenterXConstraint = wayNameView.centerXAnchor.constraint(equalTo: safeCenterXAnchor)
            let wayNameViewWidthConstraint = wayNameView.widthAnchor.constraint(lessThanOrEqualTo: safeWidthAnchor)
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
                                                                                 constant: 12)
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
                if orientation == .landscapeRight {
                    speedLimitViewTrailingConstraint = speedLimitView.trailingAnchor.constraint(equalTo: margins.trailingAnchor)
                } else {
                    speedLimitViewTrailingConstraint = speedLimitView.trailingAnchor.constraint(equalTo: margins.trailingAnchor)
                }
                
                defaultSpeedLimitViewConstraints.append(speedLimitViewTrailingConstraint)
            case .topTrailing:
                let speedLimitViewLeadingContraint = speedLimitView.leadingAnchor.constraint(equalTo: margins.leadingAnchor)
                
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
        
        // FIXME: leading anchor is not big enough
        let topBannerContainerViewLeadingConstraint = topBannerContainerView.leadingAnchor.constraint(equalTo: safeLeadingAnchor)
        let topBannerContainerViewTrailingConstraint = topBannerContainerView.trailingAnchor.constraint(equalTo: margins.trailingAnchor,
                                                                                                        constant: -UIScreen.main.bounds.width * 0.4)
        let topBannerContainerViewTopConstraint = topBannerContainerView.topAnchor.constraint(equalTo: margins.topAnchor)
        
        let topBannerConstraints = [
            topBannerContainerViewLeadingConstraint,
            topBannerContainerViewTrailingConstraint,
            topBannerContainerViewTopConstraint
        ]
        
        layoutConstraints.append(contentsOf: topBannerConstraints)
        
        let floatingStackViewTopConstraint = floatingStackView.topAnchor.constraint(equalTo: margins.topAnchor)
        
        layoutConstraints.append(floatingStackViewTopConstraint)
        
        if let floatingStackViewLayoutGuide = floatingStackViewLayoutGuide {
            let floatingStackViewLayoutConstraints = floatingStackViewLayoutGuide.layoutConstraints(for: floatingStackView)
            layoutConstraints.append(contentsOf: floatingStackViewLayoutConstraints)
        } else {
            switch floatingButtonsPosition {
            case .topLeading:
                print("!!! top leading compact")
                let floatingStackViewLeadingConstraint = floatingStackView.leadingAnchor.constraint(equalTo: topBannerContainerView.trailingAnchor)
                
                layoutConstraints.append(floatingStackViewLeadingConstraint)
            case .topTrailing:
                print("!!! top trailing compact")
                let floatingStackViewTrailingConstraint: NSLayoutConstraint
                // Device is in landscape mode and notch (if present) is located on the left side.
                if orientation == .landscapeRight {
                    if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
                        print("!!! if if")
                        // Language with right-to-left interface layout is used.
                        floatingStackViewTrailingConstraint = floatingStackView.trailingAnchor.constraint(equalTo: safeTrailingAnchor,
                                                                                                          constant: -20)
                    } else {
                        print("!!! if else")
                        // Language with left-to-right interface layout is used.
                        floatingStackViewTrailingConstraint = floatingStackView.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                                                                          constant: -20)
                    }
                } else {
                    if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
                        print("!!! else if")
                        floatingStackViewTrailingConstraint = floatingStackView.trailingAnchor.constraint(equalTo: margins.trailingAnchor)
                    } else {
                        print("!!! else else")
                        floatingStackViewTrailingConstraint = floatingStackView.trailingAnchor.constraint(equalTo: margins.trailingAnchor)
                    }
                }
                
                layoutConstraints.append(floatingStackViewTrailingConstraint)
            }
        }
        
        let bottomBannerContainerViewTrailingConstraint = bottomBannerContainerView.trailingAnchor.constraint(equalTo: topBannerContainerView.trailingAnchor)
//        let bottomBannerContainerViewLeadingConstraint = bottomBannerContainerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20)
        let bottomBannerContainerViewLeadingConstraint = bottomBannerContainerView.leadingAnchor.constraint(equalTo: topBannerContainerView.leadingAnchor)
        
        let bottomBannerConstraints = [
            bottomBannerContainerViewTrailingConstraint,
            bottomBannerContainerViewLeadingConstraint
        ]
        
        layoutConstraints.append(contentsOf: bottomBannerConstraints)
        
        let resumeButtonLeadingConstraint: NSLayoutConstraint
        if orientation == .landscapeRight {
            if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
                resumeButtonLeadingConstraint = resumeButton.leadingAnchor.constraint(equalTo: margins.leadingAnchor)
            } else {
                resumeButtonLeadingConstraint = resumeButton.leadingAnchor.constraint(equalTo: margins.leadingAnchor)
            }
        } else {
            if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
                resumeButtonLeadingConstraint = resumeButton.leadingAnchor.constraint(equalTo: margins.leadingAnchor)
            } else {
                resumeButtonLeadingConstraint = resumeButton.leadingAnchor.constraint(equalTo: margins.leadingAnchor)
            }
        }
        
        let resumeButtonBottomConstraint = resumeButton.bottomAnchor.constraint(equalTo: bottomBannerContainerView.topAnchor,
                                                                                constant: -12)
        
        let resumeButtonConstraints = [
            resumeButtonLeadingConstraint,
            resumeButtonBottomConstraint
        ]
        
        layoutConstraints.append(contentsOf: resumeButtonConstraints)
        
        let wayNameViewConstraints: [NSLayoutConstraint]
        // FIXME: need center and width anchors constrained to area between bottom banner and trailing edge in landscape
        if let wayNameViewLayoutGuide = wayNameViewLayoutGuide {
            wayNameViewConstraints = wayNameViewLayoutGuide.layoutConstraints(for: wayNameView)
        } else {
            let wayNameViewBottomConstraint: NSLayoutConstraint
            
            if orientation == .landscapeLeft || orientation == .landscapeRight {
                wayNameViewBottomConstraint = wayNameView.bottomAnchor.constraint(equalTo: safeBottomAnchor,
                                                                                      constant: -16)
            } else {
                wayNameViewBottomConstraint = wayNameView.bottomAnchor.constraint(equalTo: bottomBannerContainerView.topAnchor,
                                                                                      constant: -12)
            }
            let wayNameViewCenterXConstraint: NSLayoutConstraint = wayNameView.centerXAnchor.constraint(equalTo: safeCenterXAnchor)
            let wayNameViewWidthConstraint: NSLayoutConstraint = wayNameView.widthAnchor.constraint(lessThanOrEqualTo: safeWidthAnchor)
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
            let speedLimitViewTopContraint = speedLimitView.topAnchor.constraint(equalTo: margins.topAnchor)
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
                if orientation == .landscapeRight {
                    speedLimitViewTrailingConstraint = speedLimitView.trailingAnchor.constraint(equalTo: margins.trailingAnchor)
                } else {
                    speedLimitViewTrailingConstraint = speedLimitView.trailingAnchor.constraint(equalTo: margins.trailingAnchor)
                }
                
                defaultSpeedLimitViewConstraints.append(speedLimitViewTrailingConstraint)
            case .topTrailing:
                let speedLimitViewLeadingContraint = speedLimitView.leadingAnchor.constraint(equalTo: topBannerContainerView.trailingAnchor,
                                                                                             constant: 12)
                
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
}
