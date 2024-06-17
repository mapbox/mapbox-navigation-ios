import MapboxNavigationCore
import UIKit

/// ``TopBannerViewControllerDelegate`` provides methods for reacting to the user interactions with
/// ``TopBannerViewController``. Such interactions include:
/// - ``InstructionsBannerView`` swiping to the left, right, top and bottom.
/// - ``StepTableViewCell`` selection.
/// - Display or dismissal of ``StepsViewController``, which shows list of remaining legs and steps.
public protocol TopBannerViewControllerDelegate: VisualInstructionDelegate, UnimplementedLogging {
    /// A method that is invoked when the user swipes ``InstructionsBannerView`` in a certain direction.
    /// - Parameters:
    ///   - banner: The ``TopBannerViewController`` instance.
    ///   - direction: Direction, in which swiping was performed: (either `.left`, `.right`, `.top` or `.bottom`).
    func topBanner(_ banner: TopBannerViewController, didSwipeInDirection direction: UISwipeGestureRecognizer.Direction)

    /// A method that is invoked when the user selects certain step in a ``TopBannerViewController`` drop-down menu.
    /// - Parameters:
    ///   - banner: The ``TopBannerViewController`` instance.
    ///   - legIndex: The zero-based index of the currently active leg along the active route.
    ///   - stepIndex: The zero-based index of the currently active step along the active route.
    ///   - cell: The ``StepTableViewCell`` instance, which contains visual information regarding maneuver.
    func topBanner(_ banner: TopBannerViewController, didSelect legIndex: Int, stepIndex: Int, cell: StepTableViewCell)

    ///  Tells the delegate the ``TopBannerViewController`` is about to display a ``StepsViewController`` as a
    /// drop-down.
    /// - Parameters:
    ///   - banner: The ``TopBannerViewController`` instance.
    ///   - willDisplayStepsController: The ``StepsViewController`` instance, which is about to be shown as a drop-down.
    func topBanner(_ banner: TopBannerViewController, willDisplayStepsController: StepsViewController)

    /// Tells the delegate the ``TopBannerViewController`` that ``StepsViewController`` was displayed as a drop-down.
    /// - Parameters:
    ///   - banner: The ``TopBannerViewController`` instance.
    ///   - didDisplayStepsController: The ``StepsViewController`` instance, which was displayed as a drop-down.
    func topBanner(_ banner: TopBannerViewController, didDisplayStepsController: StepsViewController)

    ///  Tells the delegate the ``TopBannerViewController`` is about to dismiss and hide a ``StepsViewController``
    /// drop-down.
    /// - Parameters:
    ///   - banner: The ``TopBannerViewController`` instance.
    ///   - willDismissStepsController:  The ``StepsViewController`` instance, which is about to be dismissed.
    func topBanner(_ banner: TopBannerViewController, willDismissStepsController: StepsViewController)

    /// Tells the delegate the ``TopBannerViewController`` that ``StepsViewController`` was dismissed.
    /// - Parameters:
    ///   - banner: The ``TopBannerViewController`` instance.
    ///   - didDismissStepsController: The ``StepsViewController`` instance, which was dismissed.
    func topBanner(_ banner: TopBannerViewController, didDismissStepsController: StepsViewController)
}

extension TopBannerViewControllerDelegate {
    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func topBanner(
        _ banner: TopBannerViewController,
        didSwipeInDirection direction: UISwipeGestureRecognizer.Direction
    ) {
        logUnimplemented(protocolType: TopBannerViewControllerDelegate.self, level: .debug)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func topBanner(
        _ banner: TopBannerViewController,
        didSelect legIndex: Int,
        stepIndex: Int,
        cell: StepTableViewCell
    ) {
        logUnimplemented(protocolType: TopBannerViewControllerDelegate.self, level: .debug)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func topBanner(_ banner: TopBannerViewController, willDisplayStepsController: StepsViewController) {
        logUnimplemented(protocolType: TopBannerViewControllerDelegate.self, level: .debug)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func topBanner(_ banner: TopBannerViewController, didDisplayStepsController: StepsViewController) {
        logUnimplemented(protocolType: TopBannerViewControllerDelegate.self, level: .debug)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func topBanner(_ banner: TopBannerViewController, willDismissStepsController: StepsViewController) {
        logUnimplemented(protocolType: TopBannerViewControllerDelegate.self, level: .debug)
    }

    /// `UnimplementedLogging` prints a warning to standard output the first time this method is called.
    public func topBanner(_ banner: TopBannerViewController, didDismissStepsController: StepsViewController) {
        logUnimplemented(protocolType: TopBannerViewControllerDelegate.self, level: .debug)
    }
}
