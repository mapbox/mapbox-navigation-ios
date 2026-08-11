import UIKit

enum CarPlayMapButtonsPlacement: Equatable {
    case leading
    case trailing
}

// Tracks CarPlay safe-area insets while transient controls are hidden, allowing later inset growth to identify them.
struct CarPlaySafeAreaInsetsBaseline {
    private var minimumTopSafeAreaInset: CGFloat?
    private var settledHorizontalSafeAreaInsets: UIEdgeInsets?
    private var hasObservedControlsVisible = false
    private var isHorizontalPlacementConfirmed = false

    mutating func update(
        with safeAreaInsets: UIEdgeInsets,
        controlsVisibilityThreshold: CGFloat = CarPlayUtilities.safeAreaControlsVisibilityThreshold
    ) {
        guard safeAreaInsets != .zero else { return }

        // The top inset can contain a persistent, vehicle-specific reservation larger than the controls threshold.
        // Keep the smallest observed value so only later growth is interpreted as the navigation bar.
        let previousMinimumTopSafeAreaInset = minimumTopSafeAreaInset
        let observedLowerTopInset = minimumTopSafeAreaInset.map { safeAreaInsets.top < $0 } ?? false
        if let minimumTopSafeAreaInset {
            self.minimumTopSafeAreaInset = min(minimumTopSafeAreaInset, safeAreaInsets.top)
        } else {
            minimumTopSafeAreaInset = safeAreaInsets.top
        }

        guard let minimumTopSafeAreaInset else { return }
        let hasTopInsetGrowth = safeAreaInsets.top > minimumTopSafeAreaInset + controlsVisibilityThreshold
        let hasHighInitialTopInset =
            previousMinimumTopSafeAreaInset == nil
                && safeAreaInsets.top > controlsVisibilityThreshold
        if hasTopInsetGrowth || hasHighInitialTopInset {
            hasObservedControlsVisible = true
        }

        guard safeAreaInsets.top <= controlsVisibilityThreshold || observedLowerTopInset,
              !hasTopInsetGrowth
        else {
            // A high initial top inset is ambiguous because the navigation bar may already be visible. Wait for a
            // controls-hidden layout before learning which side is persistently reserved.
            return
        }

        // Keep only horizontal insets because they describe the persistent side reservation, such as the apps panel.
        let horizontalSafeAreaInsets = UIEdgeInsets(
            top: 0,
            left: safeAreaInsets.left,
            bottom: 0,
            right: safeAreaInsets.right
        )

        guard let settledHorizontalSafeAreaInsets else {
            self.settledHorizontalSafeAreaInsets = horizontalSafeAreaInsets
            isHorizontalPlacementConfirmed = hasObservedControlsVisible
            return
        }

        guard settledHorizontalSafeAreaInsets != horizontalSafeAreaInsets else {
            if hasObservedControlsVisible {
                isHorizontalPlacementConfirmed = true
            }
            return
        }

        // Persistent UI can change when entering active guidance, for example when the guidance panel replaces the
        // browsing layout. Adopt that settled layout as the new baseline. Navigation-bar and map-button insets are not
        // learned because they arrive with the top-inset growth excluded above.
        self.settledHorizontalSafeAreaInsets = horizontalSafeAreaInsets
        isHorizontalPlacementConfirmed = hasObservedControlsVisible
    }

    func carPlayControlsAreVisible(for safeAreaInsets: UIEdgeInsets, threshold: CGFloat) -> Bool {
        // Without a baseline, persistent display insets cannot be distinguished from transient controls. Treat them as
        // persistent so an unknown baseline cannot keep the speed-limit view hidden indefinitely.
        guard let minimumTopSafeAreaInset else { return false }

        // Top safe-area growth relative to the persistent inset tracks the CarPlay navigation bar.
        if safeAreaInsets.top > minimumTopSafeAreaInset + threshold {
            return true
        }

        guard let settledHorizontalSafeAreaInsets else { return false }

        // Horizontal growth relative to the baseline tracks the CarPlay map buttons stack.
        return safeAreaInsets.left > settledHorizontalSafeAreaInsets.left + threshold
            || safeAreaInsets.right > settledHorizontalSafeAreaInsets.right + threshold
    }

    func mapButtonsPlacement(for _: UIEdgeInsets) -> CarPlayMapButtonsPlacement {
        // Before a settled baseline is available, current insets may already include transient right-side map controls
        // and incorrectly suggest that the applications panel is on the right. Default to the standard trailing
        // placement until the persistent panel side is known.
        guard let settledHorizontalSafeAreaInsets, isHorizontalPlacementConfirmed else {
            return .trailing
        }

        // Map buttons are placed opposite the persistent apps panel. If the right side is reserved, they use leading.
        guard settledHorizontalSafeAreaInsets.right > settledHorizontalSafeAreaInsets.left else {
            return .trailing
        }
        return .leading
    }
}

enum CarPlayUtilities {
    static let safeAreaControlsVisibilityThreshold: CGFloat = 38
    static let controlsDismissalVisibilityDelay: TimeInterval = 0.2
    static let previewCameraAnimationDuration: TimeInterval = 0.3

    /// Derived from the 480-pixel height of the standard 800×480 CarPlay display resolution.
    static let compactMapOverlayShortEdgeThresholdInPixels: CGFloat = 480
    /// Keeps route-line overlays proportional to the smaller usable map area on compact CarPlay displays.
    static let compactRouteLineWidthMultiplier = 0.7

    static func usesCompactMapOverlays(forNativeScreenSize screenSize: CGSize) -> Bool {
        min(screenSize.width, screenSize.height) <= compactMapOverlayShortEdgeThresholdInPixels
    }

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
