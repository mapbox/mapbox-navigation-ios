import CoreGraphics
import MapboxDirections
import MapboxNavigationCore
import UIKit

enum CarPlaySpeedLimitViewConfiguration {
    struct Layout: Equatable {
        let size: CGSize
        let topPadding: CGFloat
        let sidePadding: CGFloat
    }

    static func layout(for signStandard: SignStandard?) -> Layout {
        switch signStandard {
        case .mutcd:
            return Layout(
                size: CGSize(width: 36, height: 36),
                topPadding: 6,
                sidePadding: 3
            )
        case .viennaConvention, nil:
            return Layout(
                size: CGSize(width: 36, height: 36),
                topPadding: 3,
                sidePadding: 3
            )
        }
    }

    static func shouldHideSpeedLimitView(
        activity: CarPlayActivity?,
        cameraState: NavigationCameraState,
        areCarPlayControlsVisible: Bool,
        isCameraRecenterOffered: Bool
    ) -> Bool {
        guard !areCarPlayControlsVisible else { return true }

        switch activity {
        case .panningInBrowsingMode, .panningInNavigationMode, .previewing:
            return true
        case .browsing, .navigating, nil:
            break
        }

        return cameraState != .following || isCameraRecenterOffered
    }
}

@MainActor
final class CarPlaySpeedLimitViewVisibilityCoordinator {
    private var pendingRevealWorkItem: DispatchWorkItem?

    deinit {
        pendingRevealWorkItem?.cancel()
    }

    func update(
        speedLimitViewContainer: UIView,
        shouldHide: @MainActor @escaping () -> Bool
    ) {
        if shouldHide() {
            pendingRevealWorkItem?.cancel()
            pendingRevealWorkItem = nil
            speedLimitViewContainer.isHidden = true
            return
        }

        guard speedLimitViewContainer.isHidden else { return }
        guard pendingRevealWorkItem == nil else { return }

        let workItem = DispatchWorkItem { [weak self, weak speedLimitViewContainer] in
            guard let self else { return }
            pendingRevealWorkItem = nil

            guard let speedLimitViewContainer, !shouldHide() else {
                return
            }

            speedLimitViewContainer.isHidden = false
        }
        pendingRevealWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + CarPlayUtilities.controlsDismissalVisibilityDelay,
            execute: workItem
        )
    }
}
