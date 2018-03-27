import UIKit

extension CLLocationDirection {
    
    // Minimize the rotation by taking the shorter path around
    mutating func normalizeAngle(_ anchorAngle: CLLocationDirection) -> CLLocationDirection {
        self = self.wrap(min: 0, max: 360)
        let diff = abs(self - anchorAngle)
        
        if (abs(self - 180 - anchorAngle) < diff) {
            self -= 360
        }
        
        if (abs(self + 180 - anchorAngle) < diff) {
            self += 360
        }
        
        return self
    }
}

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
    
    var direction: CLLocationDirection {
        set {
            guard let layer = layer as? NavigationCameraLayer else { return }
            var newDirection = newValue
            layer.direction = newDirection.normalizeAngle(layer.direction)
        }
        get {
            guard let layer = layer as? NavigationCameraLayer else { return 0 }
            return layer.direction
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
    
    var isTransitioning: Bool = false
    
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
    
    override func display(_ layer: CALayer) {
        guard let presentationLayer = layer.presentation() as? NavigationCameraLayer else { return }
        
        let camera = mapView.camera
        camera.altitude = presentationLayer.altitude
        camera.pitch = presentationLayer.pitch
        camera.centerCoordinate = CLLocationCoordinate2D(latitude: presentationLayer.centerLatitude, longitude: presentationLayer.centerLongitude)
        camera.heading = presentationLayer.direction
        mapView.setCamera(camera, animated: false)
    }
}
