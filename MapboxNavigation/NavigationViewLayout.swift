import UIKit

extension NavigationView {
    func setupConstraints() {
        mapView.topAnchor.constraint(equalTo: instructionsBannerView.bottomAnchor).isActive = true
        mapView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        mapView.bottomAnchor.constraint(equalTo: bottomBannerContentView.topAnchor).isActive = true
        mapView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        
        instructionsBannerContentView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        instructionsBannerContentView.bottomAnchor.constraint(equalTo: instructionsBannerView.bottomAnchor).isActive = true
        instructionsBannerContentView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        
        instructionsBannerView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        instructionsBannerView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        instructionsBannerView.heightAnchor.constraint(equalToConstant: 96).isActive = true
        
        NSLayoutConstraint.activate(bannerShowConstraints)
        separatorView.topAnchor.constraint(equalTo: instructionsBannerView.bottomAnchor).isActive = true
        separatorView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        separatorView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        separatorView.heightAnchor.constraint(equalToConstant: 2).isActive = true

        informationStackView.topAnchor.constraint(equalTo: instructionsBannerView.bottomAnchor).isActive = true
        informationStackView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        informationStackView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        
        floatingStackView.topAnchor.constraint(equalTo: informationStackView.bottomAnchor, constant: 10).isActive = true
        floatingStackView.rightAnchor.constraint(equalTo: safeRightAnchor, constant: -10).isActive = true
        
        resumeButton.leftAnchor.constraint(equalTo: safeLeftAnchor, constant: 10).isActive = true
        resumeButton.bottomAnchor.constraint(equalTo: bottomBannerView.topAnchor, constant: -10).isActive = true
        
        rerouteReportButton.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        rerouteReportButton.topAnchor.constraint(equalTo: informationStackView.bottomAnchor, constant: 10).isActive = true
        
        bottomBannerContentView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        bottomBannerContentView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        bottomBannerContentView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        bottomBannerContentView.topAnchor.constraint(equalTo: bottomBannerView.topAnchor).isActive = true
        
        bottomBannerView.heightAnchor.constraint(equalToConstant: 80).isActive = true
        bottomBannerView.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        bottomBannerView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        bottomBannerView.bottomAnchor.constraint(equalTo: safeBottomAnchor).isActive = true
        
        wayNameLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        wayNameLabel.bottomAnchor.constraint(equalTo: bottomBannerView.topAnchor, constant: -10).isActive = true
    }

    func constrainEndOfRoute() {
        self.endOfRouteHideConstraint?.isActive = true
        
        endOfRouteView?.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        endOfRouteView?.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        self.endOfRouteHeightConstraint?.isActive = true
        
    }
}
