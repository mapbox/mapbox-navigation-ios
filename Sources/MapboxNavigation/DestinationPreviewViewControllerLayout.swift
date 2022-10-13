import UIKit

extension DestinationPreviewViewController {
    
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
        
        let startButtonLayoutConstraints = [
            startButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            startButton.trailingAnchor.constraint(equalTo: bottomBannerView.trailingAnchor,
                                                  constant: -10.0),
            startButton.topAnchor.constraint(equalTo: bottomBannerView.topAnchor,
                                             constant: 10.0),
            startButton.bottomAnchor.constraint(equalTo: bottomBannerView.bottomAnchor,
                                                constant: -10.0)
        ]
        
        NSLayoutConstraint.activate(startButtonLayoutConstraints)
        
        let previewButtonLayoutConstraints = [
            previewButton.widthAnchor.constraint(equalToConstant: buttonWidth),
            previewButton.trailingAnchor.constraint(equalTo: startButton.leadingAnchor,
                                                    constant: -10.0),
            previewButton.topAnchor.constraint(equalTo: bottomBannerView.topAnchor,
                                               constant: 10.0),
            previewButton.bottomAnchor.constraint(equalTo: bottomBannerView.bottomAnchor,
                                                  constant: -10.0)
        ]
        
        NSLayoutConstraint.activate(previewButtonLayoutConstraints)
        
        let destinationLabelLayoutConstraints = [
            destinationLabel.leadingAnchor.constraint(equalTo: bottomBannerView.leadingAnchor,
                                                      constant: 10.0),
            destinationLabel.trailingAnchor.constraint(equalTo: previewButton.leadingAnchor,
                                                       constant: -10.0),
            destinationLabel.topAnchor.constraint(equalTo: bottomBannerView.topAnchor,
                                                  constant: 10.0),
            destinationLabel.bottomAnchor.constraint(equalTo: bottomBannerView.safeBottomAnchor,
                                                     constant: -10.0)
        ]
        
        NSLayoutConstraint.activate(destinationLabelLayoutConstraints)
        
        let separatorViewThickness = 1 / UIScreen.main.scale
        
        let separatorViewsConstraints = [
            verticalSeparatorView.widthAnchor.constraint(equalToConstant: separatorViewThickness),
            verticalSeparatorView.topAnchor.constraint(equalTo: bottomBannerView.topAnchor,
                                                       constant: 10.0),
            verticalSeparatorView.bottomAnchor.constraint(equalTo: bottomBannerView.bottomAnchor,
                                                          constant: -10.0),
            verticalSeparatorView.centerYAnchor.constraint(equalTo: bottomBannerView.centerYAnchor),
            verticalSeparatorView.leadingAnchor.constraint(equalTo: previewButton.trailingAnchor,
                                                           constant: 5.0),
            
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
