import Combine
import MapboxNavigationCore
import UIKit

class CameraModeFloatingButton: FloatingButton {
    var cameraMode: Preview.CameraMode = .centered {
        didSet {
            updateImage(for: cameraMode)
        }
    }

    weak var navigationView: NavigationView? = nil {
        didSet {
            cancellable = navigationView?.navigationMapView.navigationCamera.cameraStates
                .sink { [weak self] state in self?.navigationCameraStateChanged(state) }
        }
    }

    private var cancellable: AnyCancellable?

    func updateImage(for cameraMode: Preview.CameraMode) {
        let image: UIImage = switch cameraMode {
        case .idle:
            .recenterImage
        case .centered:
            .followImage
        case .following:
            .northUpImage
        }

        setImage(image, for: .normal)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        commonInit()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func commonInit() {
        cameraMode = .centered
        addTarget(self, action: #selector(didPress), for: .touchUpInside)
    }

    func navigationCameraStateChanged(_ state: NavigationCameraState) {
        switch state {
        case .idle:
            cameraMode = .idle
        case .following, .overview:
            break
        }
    }

    @objc
    func didPress() {
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
