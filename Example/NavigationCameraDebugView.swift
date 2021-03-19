import UIKit
import MapboxMaps
import MapboxNavigation

class NavigationCameraDebugView: UIView {
    
    weak var mapView: MapView?
    
    var viewportLayer = CALayer()
    var anchorLayer = CALayer()
    
    required init(_ mapView: MapView, frame: CGRect) {
        self.mapView = mapView
        
        super.init(frame: frame)
        
        isUserInteractionEnabled = false
        backgroundColor = .clear
        subscribeForNotifications()
        
        viewportLayer.borderWidth = 5
        viewportLayer.borderColor = UIColor.green.cgColor
        layer.addSublayer(viewportLayer)
        
        anchorLayer.backgroundColor = UIColor.red.cgColor
        anchorLayer.frame = .init(x: 0.0, y: 0.0, width: 10.0, height: 10.0)
        anchorLayer.cornerRadius = 5.0
        layer.addSublayer(anchorLayer)
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
                                         width: mapView.cameraView.frame.width - edgeInsets.left - edgeInsets.right,
                                         height: mapView.cameraView.frame.height - edgeInsets.top - edgeInsets.bottom)
        }
        
        if let anchorPosition = followingMobileCamera.anchor {
            anchorLayer.position = anchorPosition
        }
    }
}
