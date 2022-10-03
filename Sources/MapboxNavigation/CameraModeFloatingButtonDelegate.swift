protocol CameraModeFloatingButtonDelegate: AnyObject {
    
    func cameraModeFloatingButton(_ cameraModeFloatingButton: CameraModeFloatingButton,
                                  cameraModeDidChangeTo cameraMode: Preview.CameraMode)
}
