import UIKit

extension PreviewViewController {
    
    func setupConstraints() {
        // Layout guide is used to modify default position of the `SpeedLimitView`.
        let speedLimitViewLayoutGuide = UILayoutGuide()
        navigationView.addLayoutGuide(speedLimitViewLayoutGuide)
        
        let speedLimitViewLayoutGuideLayoutConstraints = [
            speedLimitViewLayoutGuide.topAnchor.constraint(equalTo: view.safeTopAnchor,
                                                           constant: 10.0),
            speedLimitViewLayoutGuide.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor,
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
        
        // Layout guide is used to modify default position of the `UIStackView` with floating buttons.
        let floatingStackViewLayoutGuide = UILayoutGuide()
        navigationView.addLayoutGuide(floatingStackViewLayoutGuide)
        
        let floatingStackViewLayoutGuideLayoutConstraints = [
            floatingStackViewLayoutGuide.topAnchor.constraint(equalTo: view.safeTopAnchor,
                                                              constant: 10.0),
            floatingStackViewLayoutGuide.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor,
                                                                   constant: -10.0)
        ]
        
        NSLayoutConstraint.activate(floatingStackViewLayoutGuideLayoutConstraints)
        navigationView.floatingStackViewLayoutGuide = floatingStackViewLayoutGuide
    }
}
