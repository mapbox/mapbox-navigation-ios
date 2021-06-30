import UIKit
import MapboxMaps

/**
 `UIView`, which is drawn on top of `MapView` and shows `CameraOptions` when `NavigationCamera` is in
 `NavigationCameraState.following` state.
 
 Such `UIView` is useful for debugging purposes (especially when debugging camera behavior on CarPlay).
 */
class NavigationCameraDebugView: UIView {
    
    weak var mapView: MapView?
    
    let navigationCameraType: NavigationCameraType
    
    weak var navigationViewportDataSource: NavigationViewportDataSource? {
        didSet {
            subscribeForNotifications(navigationViewportDataSource)
        }
    }
    
    var viewportLayer = CALayer()
    var viewportTextLayer = CATextLayer()
    var anchorLayer = CALayer()
    var anchorTextLayer = CATextLayer()
    var centerLayer = CALayer()
    var centerTextLayer = CATextLayer()
    var pitchTextLayer = CATextLayer()
    var zoomTextLayer = CATextLayer()
    var bearingTextLayer = CATextLayer()
    var centerCoordinateTextLayer = CATextLayer()
    
    required init(_ mapView: MapView,
                  frame: CGRect,
                  navigationCameraType: NavigationCameraType,
                  navigationViewportDataSource: NavigationViewportDataSource?) {
        self.mapView = mapView
        self.navigationCameraType = navigationCameraType
        self.navigationViewportDataSource = navigationViewportDataSource
        
        super.init(frame: frame)
        
        isUserInteractionEnabled = false
        backgroundColor = .clear
        subscribeForNotifications(navigationViewportDataSource)
        
        viewportLayer.borderWidth = 3.0
        viewportLayer.borderColor = UIColor.green.cgColor
        layer.addSublayer(viewportLayer)
        
        anchorLayer.backgroundColor = UIColor.red.cgColor
        anchorLayer.frame = .init(x: 0.0, y: 0.0, width: 6.0, height: 6.0)
        anchorLayer.cornerRadius = 3.0
        layer.addSublayer(anchorLayer)
        
        anchorTextLayer = CATextLayer()
        anchorTextLayer.string = "Anchor"
        anchorTextLayer.fontSize = UIFont.systemFontSize
        anchorTextLayer.backgroundColor = UIColor.clear.cgColor
        anchorTextLayer.foregroundColor = UIColor.red.cgColor
        anchorTextLayer.frame = .zero
        layer.addSublayer(anchorTextLayer)
        
        centerLayer.backgroundColor = UIColor.blue.cgColor
        centerLayer.frame = .init(x: 0.0, y: 0.0, width: 6.0, height: 6.0)
        centerLayer.cornerRadius = 3.0
        layer.addSublayer(centerLayer)
        
        centerTextLayer = CATextLayer()
        centerTextLayer.string = "Center"
        centerTextLayer.fontSize = UIFont.systemFontSize
        centerTextLayer.backgroundColor = UIColor.clear.cgColor
        centerTextLayer.foregroundColor = UIColor.blue.cgColor
        centerTextLayer.frame = .zero
        layer.addSublayer(centerTextLayer)
        
        pitchTextLayer = createDefaultTextLayer()
        layer.addSublayer(pitchTextLayer)
        
        zoomTextLayer = createDefaultTextLayer()
        layer.addSublayer(zoomTextLayer)
        
        bearingTextLayer = createDefaultTextLayer()
        layer.addSublayer(bearingTextLayer)
        
        viewportTextLayer = createDefaultTextLayer()
        layer.addSublayer(viewportTextLayer)
        
        centerCoordinateTextLayer = createDefaultTextLayer()
        layer.addSublayer(centerCoordinateTextLayer)
    }
    
    func createDefaultTextLayer() -> CATextLayer {
        let textLayer = CATextLayer()
        textLayer.string = ""
        textLayer.fontSize = UIFont.systemFontSize
        textLayer.backgroundColor = UIColor.clear.cgColor
        textLayer.foregroundColor = UIColor.black.cgColor
        textLayer.frame = .zero
        
        return textLayer
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        unsubscribeFromNotifications(navigationViewportDataSource)
    }
    
    func subscribeForNotifications(_ object: Any?) {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(navigationCameraViewportDidChange(_:)),
                                               name: .navigationCameraViewportDidChange,
                                               object: object)
    }
    
    func unsubscribeFromNotifications(_ object: Any?) {
        NotificationCenter.default.removeObserver(self,
                                                  name: .navigationCameraViewportDidChange,
                                                  object: object)
    }
    
    @objc func navigationCameraViewportDidChange(_ notification: NSNotification) {
        guard let mapView = mapView,
              let cameraOptions = notification.userInfo?[NavigationCamera.NotificationUserInfoKey.cameraOptions] as? Dictionary<String, CameraOptions> else { return }
        
        var camera: CameraOptions? = nil
        
        switch navigationCameraType {
        case .carPlay:
            camera = cameraOptions[CameraOptions.followingCarPlayCamera]
        case .mobile:
            camera = cameraOptions[CameraOptions.followingMobileCamera]
        }
        
        if let anchorPosition = camera?.anchor {
            anchorLayer.position = anchorPosition
            anchorTextLayer.frame = .init(x: anchorLayer.frame.origin.x + 5.0,
                                          y: anchorLayer.frame.origin.y + 5.0,
                                          width: 80.0,
                                          height: 20.0)
        }
        
        if let pitch = camera?.pitch {
            pitchTextLayer.frame = .init(x: viewportLayer.frame.origin.x + 5.0,
                                         y: viewportLayer.frame.origin.y + 5.0,
                                         width: viewportLayer.frame.size.width - 10.0,
                                         height: 20.0)
            pitchTextLayer.string = "Pitch: \(pitch)º"
        }
        
        if let zoom = camera?.zoom {
            zoomTextLayer.frame = .init(x: viewportLayer.frame.origin.x + 5.0,
                                        y: viewportLayer.frame.origin.y + 30.0,
                                        width: viewportLayer.frame.size.width - 10.0,
                                        height: 20.0)
            zoomTextLayer.string = "Zoom: \(zoom)"
        }
        
        if let bearing = camera?.bearing {
            bearingTextLayer.frame = .init(x: viewportLayer.frame.origin.x + 5.0,
                                           y: viewportLayer.frame.origin.y + 55.0,
                                           width: viewportLayer.frame.size.width - 10.0,
                                           height: 20.0)
            bearingTextLayer.string = "Bearing: \(bearing)º"
        }
        
        if let edgeInsets = camera?.padding {
            viewportLayer.frame = CGRect(x: edgeInsets.left,
                                         y: edgeInsets.top,
                                         width: mapView.frame.width - edgeInsets.left - edgeInsets.right,
                                         height: mapView.frame.height - edgeInsets.top - edgeInsets.bottom)
            
            viewportTextLayer.frame = .init(x: viewportLayer.frame.origin.x + 5.0,
                                            y: viewportLayer.frame.origin.y + 80.0,
                                            width: viewportLayer.frame.size.width - 10.0,
                                            height: 20.0)
            viewportTextLayer.string = "Padding: (top: \(edgeInsets.top), left: \(edgeInsets.left), bottom: \(edgeInsets.bottom), right: \(edgeInsets.right))"
        }
        
        if let centerCoordinate = camera?.center {
            centerLayer.position = mapView.mapboxMap.point(for: centerCoordinate)
            centerTextLayer.frame = .init(x: centerLayer.frame.origin.x + 5.0,
                                          y: centerLayer.frame.origin.y + 5.0,
                                          width: 80.0,
                                          height: 20.0)
            
            centerCoordinateTextLayer.frame = .init(x: viewportLayer.frame.origin.x + 5.0,
                                                    y: viewportLayer.frame.origin.y + 105.0,
                                                    width: viewportLayer.frame.size.width - 10.0,
                                                    height: 20.0)
            centerCoordinateTextLayer.string = "Center coordinate: (lat: \(centerCoordinate.latitude), lng: \(centerCoordinate.longitude))"
        }
    }
}
