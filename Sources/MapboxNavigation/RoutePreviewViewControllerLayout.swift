import UIKit

extension RoutePreviewViewController {
    
    func setupConstraints() {
        NSLayoutConstraint.activate([
            bottomBannerView.topAnchor.constraint(equalTo: view.topAnchor),
            bottomBannerView.bottomAnchor.constraint(equalTo: bottomPaddingView.topAnchor),
            bottomBannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            bottomPaddingView.topAnchor.constraint(equalTo: view.safeBottomAnchor),
            bottomPaddingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomPaddingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomPaddingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        
        let buttonWidth: CGFloat = 50.0
        
        NSLayoutConstraint.activate([
            startButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            startButton.trailingAnchor.constraint(equalTo: bottomBannerView.trailingAnchor,
                                                  constant: -10.0),
            startButton.topAnchor.constraint(equalTo: bottomBannerView.topAnchor,
                                             constant: 10.0),
            startButton.bottomAnchor.constraint(equalTo: bottomBannerView.bottomAnchor,
                                                constant: -10.0)
        ])
        
        NSLayoutConstraint.activate([
            timeRemainingLabel.leadingAnchor.constraint(equalTo: bottomBannerView.leadingAnchor,
                                                        constant: 10.0),
            timeRemainingLabel.lastBaselineAnchor.constraint(equalTo: bottomBannerView.centerYAnchor,
                                                             constant: 0.0),
            timeRemainingLabel.leadingAnchor.constraint(equalTo: bottomBannerView.leadingAnchor,
                                                        constant: 10.0),
            timeRemainingLabel.trailingAnchor.constraint(equalTo: bottomBannerView.trailingAnchor,
                                                         constant: -10.0)
        ])
        
        let distanceRemainingLabelWidthConstraint = distanceRemainingLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 10.0)
        distanceRemainingLabelWidthConstraint.priority = .defaultLow
        
        NSLayoutConstraint.activate([
            distanceRemainingLabel.heightAnchor.constraint(equalToConstant: 20.0),
            distanceRemainingLabel.leadingAnchor.constraint(equalTo: bottomBannerView.leadingAnchor,
                                                            constant: 10.0),
            distanceRemainingLabel.topAnchor.constraint(equalTo: timeRemainingLabel.bottomAnchor,
                                                        constant: 0.0),
            distanceRemainingLabelWidthConstraint
        ])
        
        NSLayoutConstraint.activate([
            arrivalTimeLabel.heightAnchor.constraint(equalToConstant: 20.0),
            arrivalTimeLabel.trailingAnchor.constraint(equalTo: startButton.leadingAnchor,
                                                       constant: -10.0),
            arrivalTimeLabel.leadingAnchor.constraint(equalTo: distanceRemainingLabel.trailingAnchor,
                                                      constant: 10.0),
            arrivalTimeLabel.topAnchor.constraint(equalTo: timeRemainingLabel.bottomAnchor,
                                                  constant: 0.0),
        ])
        
        let separatorViewThickness = 1 / UIScreen.main.scale
        
        let separatorViewsConstraints = [
            verticalSeparatorView.widthAnchor.constraint(equalToConstant: separatorViewThickness),
            verticalSeparatorView.topAnchor.constraint(equalTo: bottomBannerView.topAnchor, constant: 10),
            verticalSeparatorView.bottomAnchor.constraint(equalTo: bottomBannerView.bottomAnchor, constant: -10),
            verticalSeparatorView.centerYAnchor.constraint(equalTo: bottomBannerView.centerYAnchor),
            verticalSeparatorView.trailingAnchor.constraint(equalTo: startButton.leadingAnchor, constant: -5.0),
            
            horizontalSeparatorView.heightAnchor.constraint(equalToConstant: separatorViewThickness),
            horizontalSeparatorView.topAnchor.constraint(equalTo: bottomBannerView.topAnchor),
            horizontalSeparatorView.leadingAnchor.constraint(equalTo: bottomBannerView.leadingAnchor),
            horizontalSeparatorView.trailingAnchor.constraint(equalTo: bottomBannerView.trailingAnchor),
            
            trailingSeparatorView.widthAnchor.constraint(equalToConstant: separatorViewThickness),
            trailingSeparatorView.topAnchor.constraint(equalTo: bottomBannerView.topAnchor),
            trailingSeparatorView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            trailingSeparatorView.leadingAnchor.constraint(equalTo: bottomBannerView.trailingAnchor)
        ]
        
        NSLayoutConstraint.activate(separatorViewsConstraints)
    }
}
