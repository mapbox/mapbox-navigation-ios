import UIKit

extension NavigationView {
    func setupConstraints() {
        mapView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        mapView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        mapView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        mapView.logoView.bottomAnchor.constraint(equalTo: bottomBannerContainerView.topAnchor, constant: -10).isActive = true
        mapView.logoView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10).isActive = true
        mapView.attributionButton.bottomAnchor.constraint(equalTo: bottomBannerContainerView.topAnchor, constant: -10).isActive = true
        mapView.attributionButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10).isActive = true
        
        topBannerContainerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        topBannerContainerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        topBannerContainerView.topAnchor.constraint(equalTo: topAnchor).isActive = true

        floatingStackView.topAnchor.constraint(equalTo: topBannerContainerView.bottomAnchor, constant: 10).isActive = true
        floatingStackView.trailingAnchor.constraint(equalTo: safeTrailingAnchor, constant: -10).isActive = true
        
        resumeButton.leadingAnchor.constraint(equalTo: safeLeadingAnchor, constant: 10).isActive = true
        resumeButton.bottomAnchor.constraint(equalTo: bottomBannerContainerView.topAnchor, constant: -10).isActive = true

        bottomBannerContainerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        bottomBannerContainerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        bottomBannerContainerView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        wayNameView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        wayNameView.bottomAnchor.constraint(equalTo: bottomBannerContainerView.topAnchor, constant: -10).isActive = true
        
        speedLimitView.topAnchor.constraint(equalTo: topBannerContainerView.bottomAnchor, constant: 10).isActive = true
        speedLimitView.leadingAnchor.constraint(equalTo: safeLeadingAnchor, constant: 10).isActive = true
        speedLimitView.widthAnchor.constraint(equalToConstant: FloatingButton.buttonSize.width).isActive = true
        speedLimitView.heightAnchor.constraint(equalToConstant: FloatingButton.buttonSize.height).isActive = true
        
        reinstallRequiredConstraints()
    }
    
    public func reinstallRequiredConstraints() {
        if let bottomBannerContainerHeightConstraint = bottomBannerContainerHeightConstraint {
            bottomBannerContainerView.removeConstraint(bottomBannerContainerHeightConstraint)
        }
        
        var height: CGFloat = 100.0
        
        // iPhone 8, X, iPhone Xs, 11 Pro, SE (Landscape)
        if traitCollection.verticalSizeClass == .compact && traitCollection.horizontalSizeClass == .compact {
            height = 60.0
        }
        
        // iPhone 8 Plus, iPhone Xr, iPhone Xs Max, 11, 11 Pro Max (Landscape)
        if traitCollection.verticalSizeClass == .compact && traitCollection.horizontalSizeClass == .regular {
            height = 80.0
        }
        
        bottomBannerContainerHeightConstraint = bottomBannerContainerView.heightAnchor.constraint(equalToConstant: height)
        bottomBannerContainerHeightConstraint?.isActive = true
    }

    func constrainEndOfRoute() {
        self.endOfRouteHideConstraint?.isActive = true
        
        endOfRouteView?.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        endOfRouteView?.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        self.endOfRouteHeightConstraint?.isActive = true
    }
}
