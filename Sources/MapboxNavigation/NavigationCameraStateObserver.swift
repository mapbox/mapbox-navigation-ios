import Foundation

protocol NavigationCameraStateObserver: class {
    
    func navigationCameraStateDidChange(_ navigationCamera: NavigationCamera, navigationCameraState: NavigationCameraState)
}

