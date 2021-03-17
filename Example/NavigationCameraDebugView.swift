import UIKit
import MapboxMaps

class NavigationCameraDebugView: UIView {
    
    weak var mapView: MapView?
    
    var viewportLayer = CALayer()
    
    required init(_ mapView: MapView, frame: CGRect) {
        self.mapView = mapView
        
        super.init(frame: frame)
        
        isUserInteractionEnabled = false
        backgroundColor = .clear
        subscribeForNotifications()
        
        viewportLayer.borderWidth = 5
        viewportLayer.borderColor = UIColor.green.cgColor
        layer.addSublayer(viewportLayer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        unsubscribeFromNotifications()
    }
    
    func subscribeForNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(viewportDidChange(_:)),
                                               name: NSNotification.Name(rawValue: "ViewportDidChange"),
                                               object: nil)
    }
    
    func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name(rawValue: "ViewportsDidChange"),
                                                  object: nil)
    }
    
    @objc func viewportDidChange(_ notification: NSNotification) {
        if let mapView = mapView, let edgeInsets = notification.userInfo?["EdgeInsets"] as? UIEdgeInsets {
            viewportLayer.frame = CGRect(x: edgeInsets.left,
                                         y: edgeInsets.top,
                                         width: mapView.cameraView.frame.width - edgeInsets.left - edgeInsets.right,
                                         height: mapView.cameraView.frame.height - edgeInsets.top - edgeInsets.bottom)
        }
    }
}
