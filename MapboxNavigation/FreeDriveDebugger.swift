import UIKit
import Mapbox
import MapboxCoreNavigation

class CLLToMGLConverterLocationManager: NSObject, MGLLocationManager, CLLocationManagerDelegate {
    var delegate: MGLLocationManagerDelegate?

    private let locationManager: CLLocationManager

    init(locationManager: CLLocationManager) {
        self.locationManager = locationManager
        super.init()
        locationManager.delegate = self
    }

    var authorizationStatus: CLAuthorizationStatus {
        CLLocationManager.authorizationStatus()
    }

    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    var headingOrientation: CLDeviceOrientation {
        get {
            locationManager.headingOrientation
        }
        set {
            locationManager.headingOrientation = newValue
        }
    }

    func startUpdatingHeading() {
        locationManager.startUpdatingHeading()
    }

    func stopUpdatingHeading() {
        locationManager.stopUpdatingHeading()
    }

    func dismissHeadingCalibrationDisplay() {
        locationManager.dismissHeadingCalibrationDisplay()
    }

    // MARK: CLLocationManagerDelegate

    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        delegate?.locationManager(self, didUpdate: locations)
    }

    public func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        delegate?.locationManager(self, didUpdate: newHeading)
    }

    public func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return delegate?.locationManagerShouldDisplayHeadingCalibration(self) ?? false
    }

    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        delegate?.locationManager(self, didFailWithError: error)
    }
}

class FreeDriveDebugger {
    var polylineAdded: Bool = false
    private weak var mapView: NavigationMapView?
    private var polylineSource: MGLShapeSource?

    init(mapView: NavigationMapView) {
        self.mapView = mapView

        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
            if !self.polylineAdded, let style = mapView.style {
                self.addPolyline(to: style)
                self.polylineAdded = true
            }
        }
    }

    func updatePolylineWithCoordinates(coordinates: [CLLocationCoordinate2D]) {
        var mutableCoordinates = coordinates
        let polyline = MGLPolylineFeature(coordinates: &mutableCoordinates, count: UInt(mutableCoordinates.count))
        polylineSource?.shape = polyline
    }

    func addPolyline(to style: MGLStyle) {
        let source = MGLShapeSource(identifier: "polyline", shape: nil, options: nil)
        style.addSource(source)
        polylineSource = source

        let layer = MGLLineStyleLayer(identifier: "polyline", source: source)
        layer.lineJoin = NSExpression(forConstantValue: "round")
        layer.lineCap = NSExpression(forConstantValue: "round")
        layer.lineColor = NSExpression(forConstantValue: UIColor(red: 0xE2/0xff, green: 0x3D/0xff, blue: 0x5a/0xff, alpha: 1))

        layer.lineWidth = NSExpression(format: "mgl_interpolate:withCurveType:parameters:stops:($zoomLevel, 'linear', nil, %@)",
        [14: 2, 18: 12])
        style.addLayer(layer)
    }
}

func addFreeDriveDebugger(mapView: NavigationMapView) {
    let debugger = FreeDriveDebugger(mapView: mapView)

    let freeDriveLocationManager = FreeDriveLocationManager()
    let locationManager = CLLToMGLConverterLocationManager(locationManager: freeDriveLocationManager)
    mapView.locationManager = locationManager

    let debugView = freeDriveLocationManager.debugView() { from, to in
        if debugger.polylineAdded {
            debugger.updatePolylineWithCoordinates(coordinates: [from, to])
        }
    }

    mapView.addSubview(debugView)
    NSLayoutConstraint.activate([
        debugView.trailingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: -8),
        debugView.topAnchor.constraint(equalTo: mapView.topAnchor, constant: 90)
    ])
}
