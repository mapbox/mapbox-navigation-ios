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
    
    var mapView: NavigationMapView
    
    required init(_ mapView: NavigationMapView) {
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
        
        mapView.setCamera(camera, animated: false)
        
        mapView.direction = presentationLayer.course
    }
}
