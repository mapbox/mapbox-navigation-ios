import CoreGraphics
import MapboxDirections
import MapboxNavigationCore
import UIKit

enum CarPlaySpeedLimitViewConfiguration {
    // SpeedLimitView artwork is inset within its drawing canvas. In particular, the Vienna sign's visible ring occupies
    // 66 of 70 canvas units, so a 38-point view renders it at approximately 36 points, matching a 72-pixel CarPlay map
    // button on a @2x display.
    private static let size = CGSize(width: 38, height: 38)

    struct Layout: Equatable {
        let size: CGSize
        let topPadding: CGFloat
        let sidePadding: CGFloat
    }

    static func layout(for signStandard: SignStandard?) -> Layout {
        switch signStandard {
        case .mutcd:
            return Layout(
                size: size,
                topPadding: 6,
                sidePadding: 3
            )
        case .viennaConvention, nil:
            return Layout(
                size: size,
                topPadding: 3,
                sidePadding: 3
            )
        }
    }

    static func topPadding(
        for signStandard: SignStandard?,
        areCarPlayControlsVisible: Bool
    ) -> CGFloat {
        let defaultPadding = layout(for: signStandard).topPadding
        guard signStandard == .mutcd,
              areCarPlayControlsVisible
        else {
            return defaultPadding
        }
        return 3
    }

    static func shouldHideSpeedLimitView(
        activity: CarPlayActivity?,
        cameraState: NavigationCameraState,
        areCarPlayControlsVisible: Bool,
        hidesSpeedLimitViewWithMapControls: Bool = true,
        isCameraRecenterOffered: Bool
    ) -> Bool {
        if hidesSpeedLimitViewWithMapControls, areCarPlayControlsVisible {
            return true
        }

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
