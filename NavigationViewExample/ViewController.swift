import UIKit
import MapboxNavigation

class ViewController: UIViewController {
    
    var navigationView: NavigationView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationView = NavigationView(frame: view.bounds)
        navigationView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        
        let navigationViewportDataSource = NavigationViewportDataSource(navigationView.navigationMapView.mapView,
                                                                        viewportDataSourceType: .raw)
        navigationView.navigationMapView.navigationCamera.viewportDataSource = navigationViewportDataSource
        navigationView.navigationMapView.navigationCamera.follow()
        
        view.addSubview(navigationView)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.navigationView.bottomBannerContainerView.heightAnchor.constraint(equalToConstant: 150.0).isActive = true
        self.navigationView.bottomBannerContainerView.backgroundColor = .white
        self.navigationView.bottomBannerContainerView.hide(animated: false)
        
        self.navigationView.topBannerContainerView.heightAnchor.constraint(equalToConstant: 150.0).isActive = true
        self.navigationView.topBannerContainerView.backgroundColor = .white
        self.navigationView.topBannerContainerView.hide(animated: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.navigationView.bottomBannerContainerView.show(duration: 5.0)
            self.navigationView.topBannerContainerView.show(duration: 5.0)
        }
    }
}
