import UIKit

/// ``StepsViewControllerDelegate`` provides methods for user interactions in a ``StepsViewController``.
public protocol StepsViewControllerDelegate: AnyObject {
    /// Called when the user selects a step in a ``StepsViewController``.
    /// - Parameters:
    ///   - viewController: ``StepsViewController`` instance, with which user is currently interacting.
    ///   - legIndex: Zero-based index of the `RouteLeg`, which contains the maneuver.
    ///   - stepIndex: Zero-based index of the `RouteStep`, which contains the maneuver.
    ///   - cell: ``StepTableViewCell`` instance, which visually represents primary, secondary and maneuver
    /// instructions.
    func stepsViewController(
        _ viewController: StepsViewController,
        didSelect legIndex: Int,
        stepIndex: Int,
        cell: StepTableViewCell
    )

    /// Called when the user dismisses the ``StepsViewController``.
    ///
    /// - Parameter viewController: ``StepsViewController`` instance, which was dismissed.
    func didDismissStepsViewController(_ viewController: StepsViewController)
}
