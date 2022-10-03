import UIKit

// :nodoc:
public class CameraModeFloatingButton: FloatingButton {
    
    var cameraMode: Preview.CameraMode = .centered {
        didSet {
            updateImage(for: cameraMode)
            delegate?.cameraModeFloatingButton(self, cameraModeDidChangeTo: cameraMode)
        }
    }
    
    weak var delegate: CameraModeFloatingButtonDelegate?
    
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
    
    convenience init(_ frame: CGRect,
                     cameraMode: Preview.CameraMode = .following,
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
            cameraMode = .centered
        }
    }
}
