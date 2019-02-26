import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxDirections

class TopBannerViewController: ContainerViewController {
    
    lazy open var topPaddingView: TopBannerView = .forAutoLayout()
    
    lazy open var topBannerView: TopBannerView = .forAutoLayout()
    
    
    
    override func viewDidLoad() {
        addSubviews()
        setConstraints()
        
        topPaddingView.backgroundColor = .purple
        topBannerView.backgroundColor = .orange
    }
    
    func addSubviews() {
        [topPaddingView, topBannerView].forEach(view.addSubview(_:))
    }
    
    func setConstraints() {
        let constraints: [NSLayoutConstraint] = [
            topPaddingView.topAnchor.constraint(equalTo: view.topAnchor),
            topPaddingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topPaddingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topPaddingView.bottomAnchor.constraint(equalTo: topBannerView.topAnchor),
            
            topBannerView.topAnchor.constraint(equalTo: view.safeTopAnchor),
            topBannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topBannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topBannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            //TODO: Remove me
            topBannerView.heightAnchor.constraint(equalToConstant: 100)
        ]
        
        NSLayoutConstraint.activate(constraints)
    }
}
