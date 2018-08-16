import Foundation
#if canImport(CarPlay)
import CarPlay

@available(iOS 12.0, *)
class CarPlayMapViewController: UIViewController, MGLMapViewDelegate {
    
    var mapView: NavigationMapView {
        get {
            return self.view as! NavigationMapView
        }
    }

    override func loadView() {
        let mapView = NavigationMapView()
        mapView.delegate = self
//        mapView.navigationMapDelegate = self
        mapView.userTrackingMode = .follow
        mapView.logoView.isHidden = true
        mapView.attributionButton.isHidden = true
        
        self.view = mapView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    public func zoomInButton() -> CPMapButton {
        let zoomInButton = CPMapButton { [weak self] (button) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.mapView.setZoomLevel(strongSelf.mapView.zoomLevel + 1, animated: true)
        }
        zoomInButton.image = Bundle.mapboxNavigation.image(named: "plus")!
        return zoomInButton
    }
    
    public func zoomOutButton() -> CPMapButton {
        let zoomInButton = CPMapButton { [weak self] (button) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.mapView.setZoomLevel(strongSelf.mapView.zoomLevel - 1, animated: true)
        }
        zoomInButton.image = Bundle.mapboxNavigation.image(named: "minus")!
        return zoomInButton
    }
    
    public func panButton(mapTemplate: CPMapTemplate) -> CPMapButton {
        let panButton = CPMapButton { [weak self] (button) in
            guard let strongSelf = self else {
                return
            }
            if mapTemplate.isPanningInterfaceVisible {
                // TODO: Possible retain cycle. Do we need this?
                mapTemplate.dismissPanningInterface(animated: true)
                strongSelf.mapView.userTrackingMode = .follow
            } else {
                mapTemplate.showPanningInterface(animated: true)
            }
        }
        
        panButton.image = Bundle.mapboxNavigation.image(named: "pan-map")
        
        return panButton
    }
    
    // MARK: - MGLMapViewDelegate

    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        if let mapView = mapView as? NavigationMapView {
            mapView.localizeLabels()
        }
    }
}
#endif

