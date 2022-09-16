import UIKit

class CameraModeFloatingButton: FloatingButton {
    
    enum CameraMode {
        case idle
        case centered
        case following
    }
    
    var cameraMode: CameraMode = .following {
        didSet {
            updateImage(for: cameraMode)
            delegate?.cameraModeFloatingButton(self, cameraModeDidChangeTo: cameraMode)
        }
    }
    
    weak var delegate: CameraModeFloatingButtonDelegate?
    
    func updateImage(for cameraMode: CameraModeFloatingButton.CameraMode) {
        let image: UIImage
        switch cameraMode {
        case .idle:
            image = .recenter
        case .centered:
            image = .follow
        case .following:
            image = .northUp
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
    
    convenience init(_ frame: CGRect,
                     cameraMode: CameraModeFloatingButton.CameraMode = .following,
                     delegate: CameraModeFloatingButtonDelegate? = nil) {
        self.init(frame: frame)
        
        self.delegate = delegate
        self.cameraMode = cameraMode
    }
    
    func commonInit() {
        cameraMode = .following
        addTarget(self, action: #selector(didPress), for: .touchUpInside)
    }
    
    @objc func didPress() {
        switch cameraMode {
        case .idle:
            cameraMode = .centered
        case .centered:
            cameraMode = .following
        case .following:
            cameraMode = .idle
        }
    }
}
