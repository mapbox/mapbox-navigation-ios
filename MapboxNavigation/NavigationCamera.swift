import UIKit

class NavigationCamera: UIView {
    
    var altitude: CLLocationDistance {
        set {
            guard let layer = layer as? NavigationCameraLayer else { return }
            layer.altitude = newValue
        }
        get {
            guard let layer = layer as? NavigationCameraLayer else { return 0 }
            return layer.altitude
        }
    }
    
    var pitch: CGFloat {
        set {
            guard let layer = layer as? NavigationCameraLayer else { return }
            layer.pitch = newValue
        }
        get {
            guard let layer = layer as? NavigationCameraLayer else { return 0 }
            return layer.pitch
        }
    }
    
    var course: CLLocationDirection {
        set {
            guard let layer = layer as? NavigationCameraLayer else { return }
            layer.course = newValue
        }
        get {
            guard let layer = layer as? NavigationCameraLayer else { return 0 }
            return layer.course
        }
    }
    
    var centerCoordinate: CLLocationCoordinate2D {
        set {
            guard let layer = layer as? NavigationCameraLayer else { return }
            layer.centerLatitude = newValue.latitude
            layer.centerLongitude = newValue.longitude
        }
        get {
            guard let layer = layer as? NavigationCameraLayer else { return kCLLocationCoordinate2DInvalid }
            let centerCoordinate = CLLocationCoordinate2D(latitude: layer.centerLatitude, longitude: layer.centerLongitude)
            return centerCoordinate
        }
    }
    
    var mapView: NavigationMapView
    
    required init(mapView: NavigationMapView) {
        self.mapView = mapView
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override class var layerClass: AnyClass {
        return NavigationCameraLayer.self
    }
    
    // Updates the values on the presentation layer so that they can be interpolated from the current state.
    func updateValues() {
        centerCoordinate = mapView.camera.centerCoordinate
        course = mapView.direction
        pitch = mapView.camera.pitch
        altitude = mapView.altitude
    }
    
    override func display(_ layer: CALayer) {
        guard let presentationLayer = layer.presentation() as? NavigationCameraLayer else { return }
        
        let camera = mapView.camera
        camera.altitude = presentationLayer.altitude
        camera.pitch = presentationLayer.pitch
        
        let centerCoordinate = CLLocationCoordinate2D(latitude: presentationLayer.centerLatitude, longitude: presentationLayer.centerLongitude)
        camera.centerCoordinate = centerCoordinate
        
        mapView.setCamera(camera, animated: false)
        
        // TODO: Get the smallest angle and wrap properly
        mapView.direction = presentationLayer.course
    }
}
