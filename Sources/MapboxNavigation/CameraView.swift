import UIKit
import MapboxMaps

/**
 A view that represents a camera view port.
 */
public class CameraView: UIView {

    /**
     The camera's zoom. Animatable.
     */
    @objc dynamic public var zoomLevel: CGFloat {
        get {
            return CGFloat(mapView.cameraView.zoom)
        }

        set {
            layer.opacity = Float(newValue)
        }
    }
    
    /**
     The camera's bearing. Animatable.
     */
    @objc dynamic public var bearing: CLLocationDirection {
        get {
            return CLLocationDirection(mapView.cameraView.bearing)
        }

        set {
            layer.cornerRadius = CGFloat(newValue)
        }
    }

    /**
     Coordinate at the center of the camera. Animatable.
     */
    @objc dynamic public var centerCoordinate: CLLocationCoordinate2D {
        get {
            mapView.centerCoordinate
        }

        set {
            layer.position = CGPoint(x: newValue.longitude, y: newValue.latitude)
        }
    }

    /**
     The camera's pitch. Animatable.
     */
    @objc dynamic public var pitch: CGFloat {
        get {
            return mapView.cameraView.pitch
        }

        set {
            layer.bounds = CGRect(x: 0, y: 0, width: newValue, height: 0)
        }
    }
    
    /**
     The screen coordinate that the map rotates, pitches and zooms around. Setting this also affects the horizontal vanishing point when pitched. Animatable.
     */
    @objc dynamic public var anchorPoint: CGPoint {
        get {
            return layer.presentation()?.anchorPoint ?? .zero
        }

        set {
            layer.anchorPoint = newValue
        }
    }
    
    private var localCenterCoordinate: CLLocationCoordinate2D {
        let proxyCoord = layer.presentation()?.position ?? layer.position
        return CLLocationCoordinate2D(latitude: CLLocationDegrees(proxyCoord.y), longitude: CLLocationDegrees(proxyCoord.x))
    }
    
    private var localZoomLevel: Double {
        return Double(layer.presentation()?.opacity ?? layer.opacity)
    }
    
    private var localBearing: CLLocationDirection {
        return CLLocationDirection(layer.presentation()?.cornerRadius ?? layer.cornerRadius)
    }
    
    private var localPitch: CGFloat {
        return layer.presentation()?.bounds.width ?? layer.bounds.width
    }
    
    private var localAnchorPoint: CGPoint {
        return layer.presentation()?.anchorPoint ?? layer.anchorPoint
    }

    var isActive = false {
        didSet {
            setFromValuesWithMapView()
        }
    }

    private unowned var mapView: MapView!
    private var displayLink: CADisplayLink!

    public weak var delegate: CameraViewDelegate?

    init(mapView: MapView, edgeInsets: UIEdgeInsets = .zero) {
        self.mapView = mapView
        super.init(frame: .zero)
        
        self.isHidden = true
        self.isUserInteractionEnabled = false
        
        centerAnchorPointInside(edgeInsets: edgeInsets)
        setFromValuesWithMapView()
        
        displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.add(to: .current, forMode: RunLoop.Mode.common)
    }

    internal required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        displayLink.remove(from: .current, forMode: RunLoop.Mode.common)
        displayLink = nil
    }
    
    private func setFromValuesWithMapView() {
        self.zoomLevel = CGFloat(mapView.cameraView.zoom)
        self.bearing = CLLocationDirection(mapView.cameraView.bearing)
        self.pitch = CGFloat(mapView.cameraView.pitch)
        self.centerCoordinate = mapView.coordinate(for: localAnchorPoint)
    }
    
    func centerAnchorPointInside(edgeInsets: UIEdgeInsets) {
        let x = (self.mapView.bounds.size.width - edgeInsets.left - edgeInsets.right) / 2.0 + edgeInsets.left
        let y = (self.mapView.bounds.size.height - edgeInsets.top - edgeInsets.bottom) / 2.0 + edgeInsets.top
        anchorPoint = CGPoint(x: x, y: y)
    }
    
    @objc private func update() {
        let cameraOptions = CameraOptions()
        cameraOptions.center = localCenterCoordinate
        cameraOptions.zoom = CGFloat(localZoomLevel)
        cameraOptions.bearing = localBearing.wrap(min: 0, max: 360)
        cameraOptions.pitch = localPitch
        cameraOptions.padding = insetsForScreenCoordinate(localAnchorPoint, in: self.mapView)
        
        if isActive {
            self.mapView.cameraManager.setCamera(to: cameraOptions, animated: true, duration: 0, completion: nil)
        }
    }
    
    private func insetsForScreenCoordinate(_ screenCoordinate: CGPoint, in view: UIView) -> UIEdgeInsets {
        let top = screenCoordinate.y
        let left = screenCoordinate.x
        let bottom = view.bounds.size.height - top
        let right = view.bounds.size.width - left
        return UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
    }
}
