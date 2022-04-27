import MapboxNavigation
import UIKit

extension SceneDelegate: NavigationViewControllerDelegate {
    
    public func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController,
                                                   byCanceling canceled: Bool) {
        // Hide top and bottom banner containers.
        navigationViewController.navigationView.topBannerContainerView.hide()
        navigationViewController.navigationView.bottomBannerContainerView.hide(completion: { _ in
            navigationViewController.dismiss(animated: false) {
                guard let injectedNavigationMapView = navigationViewController.navigationMapView else {
                    preconditionFailure("NavigationMapView should be valid.")
                }
                
                self.previewViewController.navigationView.navigationMapView = injectedNavigationMapView
                self.previewViewController.navigationView.navigationMapView.translatesAutoresizingMaskIntoConstraints = false
                self.previewViewController.navigationView.insertSubview(injectedNavigationMapView, at: 0)
                
                let navigationView = self.previewViewController.navigationView
                let navigationMapView = navigationView.navigationMapView
                
                NSLayoutConstraint.activate([
                    navigationMapView.leadingAnchor.constraint(equalTo: navigationView.leadingAnchor),
                    navigationMapView.trailingAnchor.constraint(equalTo: navigationView.trailingAnchor),
                    navigationMapView.topAnchor.constraint(equalTo: navigationView.topAnchor),
                    navigationMapView.bottomAnchor.constraint(equalTo: navigationView.bottomAnchor),
                ])
                
                if let cameraOptions = self.initialCameraOptions {
                    navigationMapView.mapView.camera.ease(to: cameraOptions, duration: 1.0, completion: { _ in
                        self.previewViewController.setupNavigationViewportDataSource()
                        self.previewViewController.setupPassiveLocationManager()
                        self.previewViewController.navigationView.navigationMapView.navigationCamera.stop()
                        self.previewViewController.navigationView.navigationMapView.removeArrow()
                    })
                }
                
                navigationMapView.delegate = self.previewViewController
                
                self.previewViewController.navigationView.bottomBannerContainerView.show()
            }
        })
    }
}
