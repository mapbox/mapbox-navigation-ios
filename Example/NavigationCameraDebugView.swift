import UIKit
import MapboxMaps
import MapboxNavigation

class NavigationCameraDebugView: UIView {
    
    weak var mapView: MapView?
    
    var viewportLayer = CALayer()
    var anchorLayer = CALayer()
    var centerLayer = CALayer()
    var pitchLayer = CATextLayer()
    
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
        
        centerLayer.backgroundColor = UIColor.blue.cgColor
        centerLayer.frame = .init(x: 0.0, y: 0.0, width: 6.0, height: 6.0)
        centerLayer.cornerRadius = 3.0
        layer.addSublayer(centerLayer)
        
        pitchLayer = CATextLayer()
        pitchLayer.string = ""
        pitchLayer.fontSize = UIFont.systemFontSize
        pitchLayer.backgroundColor = UIColor.clear.cgColor
        pitchLayer.foregroundColor = UIColor.black.cgColor
        pitchLayer.frame = .zero
        layer.addSublayer(pitchLayer)
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
        }
        
        if let centerCoordinate = followingMobileCamera.center {
            centerLayer.position = mapView.point(for: centerCoordinate)
        }
        
        if let pitch = followingMobileCamera.pitch {
            pitchLayer.frame = .init(x: viewportLayer.frame.origin.x,
                                     y: viewportLayer.frame.origin.y,
                                     width: viewportLayer.frame.size.width,
                                     height: 30.0)
            pitchLayer.string = "Pitch: \(pitch)"
        }
    }
}
