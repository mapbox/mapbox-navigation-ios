import UIKit

extension NavigationView {
    func setupConstraints() {
        mapView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        mapView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        mapView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
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
    }

    func constrainEndOfRoute() {
        self.endOfRouteHideConstraint?.isActive = true
        
        endOfRouteView?.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        endOfRouteView?.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        self.endOfRouteHeightConstraint?.isActive = true
        
    }
}
