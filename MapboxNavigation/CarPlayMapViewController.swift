import Foundation
#if canImport(CarPlay)
import CarPlay

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

    // MARK: - MGLMapViewDelegate

    func mapView(_ mapView: MGLMapView, didFinishLoading style: MGLStyle) {
        if let mapView = mapView as? NavigationMapView {
            mapView.localizeLabels()
        }
    }
}
#endif

