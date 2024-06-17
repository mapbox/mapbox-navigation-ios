import MapboxNavigationCore
import UIKit

/// ``InstructionsBannerViewDelegate`` provides methods for reacting to user interactions in ``InstructionsBannerView``.
public protocol InstructionsBannerViewDelegate: VisualInstructionDelegate, UnimplementedLogging {
    /// Called when the user taps the ``InstructionsBannerView``.
    ///
    /// - Parameter sender: The ``BaseInstructionsBannerView`` instance.
    func didTapInstructionsBanner(_ sender: BaseInstructionsBannerView)

    /// Called when the user swipes either left, right, or down on the ``InstructionsBannerView``.
    /// - Parameters:
    ///   - sender: The ``BaseInstructionsBannerView`` instance.
    ///   - direction:  Direction, in which swiping was performed: (either `.left`, `.right`, `.top` or `.bottom`).
    func didSwipeInstructionsBanner(
        _ sender: BaseInstructionsBannerView,
        swipeDirection direction: UISwipeGestureRecognizer.Direction
    )
}

extension InstructionsBannerViewDelegate {
    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func didTapInstructionsBanner(_ sender: BaseInstructionsBannerView) {
        logUnimplemented(protocolType: InstructionsBannerViewDelegate.self, level: .debug)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func didSwipeInstructionsBanner(
        _ sender: BaseInstructionsBannerView,
        swipeDirection direction: UISwipeGestureRecognizer.Direction
    ) {
        logUnimplemented(protocolType: InstructionsBannerViewDelegate.self, level: .debug)
    }
}
