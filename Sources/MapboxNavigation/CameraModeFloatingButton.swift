import UIKit

class CameraModeFloatingButton: FloatingButton {
    
    var cameraMode: Preview.CameraMode = .centered {
        didSet {
            updateImage(for: cameraMode)
        }
    }
    
    weak var navigationView: NavigationView? = nil
    
    func updateImage(for cameraMode: Preview.CameraMode) {
        let image: UIImage
        switch cameraMode {
        case .idle:
            image = .recenterImage
        case .centered:
            image = .followImage
        case .following:
            image = .northUpImage
        }
        
        setImage(image, for: .normal)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func commonInit() {
        cameraMode = .centered
        addTarget(self, action: #selector(didPress), for: .touchUpInside)
        
        subscribeForNotifications()
    }
    
    deinit {
        unsubscribeFromNotifications()
    }
    
    // MARK: Notifications observer methods
    
    func subscribeForNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(navigationCameraStateDidChange(_:)),
                                               name: .navigationCameraStateDidChange,
                                               object: navigationView?.navigationMapView.navigationCamera)
    }
    
    func unsubscribeFromNotifications() {
        NotificationCenter.default.removeObserver(self,
                                                  name: .navigationCameraStateDidChange,
                                                  object: navigationView?.navigationMapView.navigationCamera)
    }
    
    @objc func navigationCameraStateDidChange(_ notification: Notification) {
        guard let state = notification.userInfo?[NavigationCamera.NotificationUserInfoKey.state] as? NavigationCameraState else { return }
        switch state {
        case .idle:
            cameraMode = .idle
        case .transitionToFollowing, .following, .transitionToOverview, .overview:
            break
        }
    }
    
    @objc func didPress() {
        switch cameraMode {
        case .idle:
            cameraMode = .centered
        case .centered:
            cameraMode = .following
        case .following:
            cameraMode = .centered
        }
        
        navigationView?.moveCamera(to: cameraMode)
    }
}
