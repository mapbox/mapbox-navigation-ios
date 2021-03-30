import UIKit
import MapboxMaps
import MapboxNavigation

class NavigationCameraDebugView: UIView {
    
    weak var mapView: MapView?
    
    var viewportLayer = CALayer()
    var anchorLayer = CALayer()
    var anchorTextLayer = CATextLayer()
    var centerLayer = CALayer()
    var centerTextLayer = CATextLayer()
    var pitchTextLayer = CATextLayer()
    var zoomTextLayer = CATextLayer()
    var bearingTextLayer = CATextLayer()
    
    required init(_ mapView: MapView, frame: CGRect) {
        self.mapView = mapView
        
        super.init(frame: frame)
        
        isUserInteractionEnabled = false
        backgroundColor = .clear
        subscribeForNotifications()
        
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
        unsubscribeFromNotifications()
    }
    
    func subscribeForNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(navigationCameraViewportDidChange(_:)),
                                               name: .navigationCameraViewportDidChange,
                                               object: nil)
    }
    
    func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .navigationCameraViewportDidChange,
                                                  object: nil)
    }
    
    @objc func navigationCameraViewportDidChange(_ notification: NSNotification) {
        guard let mapView = mapView,
              let cameraOptions = notification.userInfo?[NavigationCamera.NotificationUserInfoKey.cameraOptionsKey] as? Dictionary<String, CameraOptions>,
              let followingMobileCamera = cameraOptions[CameraOptions.followingMobileCameraKey] else { return }
        
        if let edgeInsets = followingMobileCamera.padding {
            viewportLayer.frame = CGRect(x: edgeInsets.left,
                                         y: edgeInsets.top,
                                         width: mapView.frame.width - edgeInsets.left - edgeInsets.right,
                                         height: mapView.frame.height - edgeInsets.top - edgeInsets.bottom)
        }
        
        if let anchorPosition = followingMobileCamera.anchor {
            anchorLayer.position = anchorPosition
            anchorTextLayer.frame = .init(x: anchorLayer.frame.origin.x + 5.0,
                                          y: anchorLayer.frame.origin.y + 5.0,
                                          width: 80.0,
                                          height: 20.0)
        }
        
        if let centerCoordinate = followingMobileCamera.center {
            centerLayer.position = mapView.point(for: centerCoordinate)
            centerTextLayer.frame = .init(x: centerLayer.frame.origin.x + 5.0,
                                          y: centerLayer.frame.origin.y + 5.0,
                                          width: 80.0,
                                          height: 20.0)
        }
        
        if let pitch = followingMobileCamera.pitch {
            pitchTextLayer.frame = .init(x: viewportLayer.frame.origin.x + 5.0,
                                         y: viewportLayer.frame.origin.y + 5.0,
                                         width: viewportLayer.frame.size.width - 10.0,
                                         height: 20.0)
            pitchTextLayer.string = "Pitch: \(pitch)"
        }
        
        if let zoom = followingMobileCamera.zoom {
            zoomTextLayer.frame = .init(x: viewportLayer.frame.origin.x + 5.0,
                                        y: viewportLayer.frame.origin.y + 30.0,
                                        width: viewportLayer.frame.size.width - 10.0,
                                        height: 20.0)
            zoomTextLayer.string = "Zoom: \(zoom)"
        }
        
        if let bearing = followingMobileCamera.bearing {
            bearingTextLayer.frame = .init(x: viewportLayer.frame.origin.x + 5.0,
                                           y: viewportLayer.frame.origin.y + 55.0,
                                           width: viewportLayer.frame.size.width - 10.0,
                                           height: 20.0)
            bearingTextLayer.string = "Bearing: \(bearing)º"
        }
    }
}
