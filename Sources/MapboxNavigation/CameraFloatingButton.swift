import UIKit

protocol CameraFloatingButtonDelegate: AnyObject {
    
    func cameraFloatingButton(_ cameraFloatingButton: CameraFloatingButton,
                              didChangeTo state: CameraFloatingButton.State)
}

class CameraFloatingButton: FloatingButton {
    
    enum State {
        case idle
        case centered
        case following
    }
    
    var cameraState: State = .following {
        didSet {
            updateImage(for: cameraState)
            delegate?.cameraFloatingButton(self, didChangeTo: cameraState)
        }
    }
    
    weak var delegate: CameraFloatingButtonDelegate?
    
    func updateImage(for state: State) {
        let imageName: String
        switch state {
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
    
    func commonInit() {
        constrainedSize = CGSize(width: 70.0, height: 50.0)
        setImage(UIImage(named: "recenter", in: .mapboxNavigation, compatibleWith: nil), for: .normal)
        imageView?.contentMode = .scaleAspectFit
        
        clipsToBounds = true
        imageEdgeInsets = UIEdgeInsets(floatLiteral: 10.0)
        backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        borderColor = #colorLiteral(red: 0.804, green: 0.816, blue: 0.816, alpha: 1)
        borderWidth = 2.0
        cornerRadius = 10.0
        
        cameraState = .following
        addTarget(self, action: #selector(didPress), for: .touchUpInside)
    }
    
    @objc func didPress() {
        switch cameraState {
        case .idle:
            cameraState = .centered
        case .centered:
            cameraState = .following
        case .following:
            cameraState = .idle
        }
    }
}
