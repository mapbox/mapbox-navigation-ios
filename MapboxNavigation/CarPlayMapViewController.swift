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
        let bundle = Bundle.mapboxNavigation
        zoomInButton.image = UIImage(named: "plus", in: bundle, compatibleWith: traitCollection)
        return zoomInButton
    }
    
    public func zoomOutButton() -> CPMapButton {
        let zoomInOut = CPMapButton { [weak self] (button) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.mapView.setZoomLevel(strongSelf.mapView.zoomLevel - 1, animated: true)
        }
        let bundle = Bundle.mapboxNavigation
        zoomInOut.image = UIImage(named: "minus", in: bundle, compatibleWith: traitCollection)
        return zoomInOut
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

        let bundle = Bundle.mapboxNavigation
        panButton.image = UIImage(named: "pan-map", in: bundle, compatibleWith: traitCollection)

        return panButton
    }
    
    // MARK: - MGLMapViewDelegate

    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        if let mapView = mapView as? NavigationMapView {
            mapView.localizeLabels()
        }
    }
    
    func mapView(_ mapView: MGLMapView, lineWidthForPolylineAnnotation annotation: MGLPolyline) -> CGFloat {
        return 6
    }
}
#endif

