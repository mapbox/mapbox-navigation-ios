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
        let imageName: String
        switch cameraMode {
        case .idle:
            imageName = "recenter"
        case .centered:
            imageName = "follow"
        case .following:
            imageName = "north-lock"
        }
        
        let image = UIImage(named: imageName, in: .mapboxNavigation, compatibleWith: nil)
        setImage(image, for: .normal)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        commonInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    convenience init(_ cameraMode: CameraModeFloatingButton.CameraMode,
                     delegate: CameraModeFloatingButtonDelegate? = nil) {
        self.init(frame: .zero)
        
        self.delegate = delegate
        self.cameraMode = cameraMode
    }
    
    func commonInit() {
        constrainedSize = CGSize(width: 50.0, height: 50.0)
        imageView?.contentMode = .scaleAspectFit
        clipsToBounds = true
        imageEdgeInsets = UIEdgeInsets(floatLiteral: 10.0)
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
