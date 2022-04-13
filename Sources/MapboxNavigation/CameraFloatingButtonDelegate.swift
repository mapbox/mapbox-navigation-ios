protocol CameraFloatingButtonDelegate: AnyObject {
    
    func cameraFloatingButton(_ cameraFloatingButton: CameraFloatingButton,
                              cameraStateDidChangeTo state: CameraFloatingButton.State)
}
