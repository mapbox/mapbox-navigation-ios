import UIKit

extension NavigationView {
    func setupConstraints() {
        mapView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        mapView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        mapView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        instructionsBannerContentView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        instructionsBannerContentView.bottomAnchor.constraint(equalTo: instructionsBannerView.bottomAnchor).isActive = true
        instructionsBannerContentView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        instructionsBannerView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        instructionsBannerView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        instructionsBannerView.heightAnchor.constraint(equalToConstant: 96).isActive = true
        
        NSLayoutConstraint.activate(bannerShowConstraints)

        informationStackView.topAnchor.constraint(equalTo: instructionsBannerView.bottomAnchor).isActive = true
        informationStackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        informationStackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        floatingStackView.topAnchor.constraint(equalTo: informationStackView.bottomAnchor, constant: 10).isActive = true
        floatingStackView.trailingAnchor.constraint(equalTo: safeTrailingAnchor, constant: -10).isActive = true
        
        resumeButton.leadingAnchor.constraint(equalTo: safeLeadingAnchor, constant: 10).isActive = true
        resumeButton.bottomAnchor.constraint(equalTo: bottomBannerStackView.topAnchor, constant: -10).isActive = true
        
        bottomBannerStackView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        bottomBannerStackView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        bottomBannerStackView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        
        // pin to the top arranged view if we have one
        if let arrangedSubview = bottomBannerStackView.arrangedSubviews.first {
            bottomBannerStackView.topAnchor.constraint(equalTo: arrangedSubview.topAnchor).isActive = true
        }
        
        wayNameView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        wayNameView.bottomAnchor.constraint(equalTo: bottomBannerStackView.topAnchor, constant: -10).isActive = true
    }

    func constrainEndOfRoute() {
        self.endOfRouteHideConstraint?.isActive = true
        
        endOfRouteView?.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        endOfRouteView?.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        self.endOfRouteHeightConstraint?.isActive = true
    }
}
