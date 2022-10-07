import UIKit

extension PreviewViewController {
    
    func setupConstraints() {
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
    }
}
