import UIKit

enum CarPlayMapButtonsPlacement: Equatable {
    case leading
    case trailing
}

// Tracks the settled CarPlay safe-area state so transient controls can be detected by later inset growth.
struct CarPlaySafeAreaInsetsBaseline {
    private var minimumHorizontalSafeAreaInsets: UIEdgeInsets?

    mutating func update(
        with safeAreaInsets: UIEdgeInsets,
        controlsVisibilityThreshold: CGFloat = CarPlayUtilities.safeAreaControlsVisibilityThreshold
    ) {
        guard safeAreaInsets != .zero else { return }

        // Top safe-area growth means the CarPlay navigation bar is visible, so do not learn a baseline from it.
        guard safeAreaInsets.top <= controlsVisibilityThreshold else {
            return
        }

        // Keep only horizontal insets because they describe the persistent side reservation, such as the apps panel.
        let horizontalSafeAreaInsets = UIEdgeInsets(
            top: 0,
            left: safeAreaInsets.left,
            bottom: 0,
            right: safeAreaInsets.right
        )

        guard let minimumHorizontalSafeAreaInsets else {
            self.minimumHorizontalSafeAreaInsets = horizontalSafeAreaInsets
            return
        }

        guard minimumHorizontalSafeAreaInsets != horizontalSafeAreaInsets else {
            return
        }

        self.minimumHorizontalSafeAreaInsets = horizontalSafeAreaInsets
    }

    func carPlayControlsAreVisible(for safeAreaInsets: UIEdgeInsets, threshold: CGFloat) -> Bool {
        // Top safe-area growth tracks the CarPlay navigation bar.
        if safeAreaInsets.top > threshold {
            return true
        }

        guard let minimumHorizontalSafeAreaInsets else { return false }

        // Horizontal growth relative to the baseline tracks the CarPlay map buttons stack.
        return safeAreaInsets.left > minimumHorizontalSafeAreaInsets.left + threshold
            || safeAreaInsets.right > minimumHorizontalSafeAreaInsets.right + threshold
    }

    func mapButtonsPlacement(
        for safeAreaInsets: UIEdgeInsets,
        controlsVisibilityThreshold: CGFloat = CarPlayUtilities.safeAreaControlsVisibilityThreshold
    ) -> CarPlayMapButtonsPlacement {
        // During startup, the navigation bar can be visible before the settled baseline is learned.
        // In that state, current asymmetric horizontal insets are the best signal for the map buttons side.
        let horizontalSafeAreaInsets = if safeAreaInsets.top > controlsVisibilityThreshold,
                                          safeAreaInsets.left != safeAreaInsets.right
        {
            safeAreaInsets
        } else if let minimumHorizontalSafeAreaInsets {
            // Once learned, the baseline identifies the persistent apps panel side.
            minimumHorizontalSafeAreaInsets
        } else {
            safeAreaInsets
        }

        // Map buttons are placed opposite the persistent apps panel. If the right side is reserved, they use leading.
        guard horizontalSafeAreaInsets.right > horizontalSafeAreaInsets.left else {
            return .trailing
        }
        return .leading
    }
}

enum CarPlayUtilities {
    static let safeAreaControlsVisibilityThreshold: CGFloat = 38
    static let controlsDismissalVisibilityDelay: TimeInterval = 0.2

    static func usesSafeTrailingConstraint(for safeAreaInsets: UIEdgeInsets) -> Bool {
        max(safeAreaInsets.left, safeAreaInsets.right) > safeAreaControlsVisibilityThreshold
    }

    static func carPlayControlsAreVisible(
        for safeAreaInsets: UIEdgeInsets,
        baseline: CarPlaySafeAreaInsetsBaseline
    ) -> Bool {
        baseline.carPlayControlsAreVisible(
            for: safeAreaInsets,
            threshold: safeAreaControlsVisibilityThreshold
        )
    }
}
