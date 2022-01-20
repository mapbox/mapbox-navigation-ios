import UIKit

/**
 `StepsViewControllerDelegate` provides methods for user interactions in a `StepsViewController`.
 */
public protocol StepsViewControllerDelegate: AnyObject {
    
    /**
     Called when the user selects a step in a `StepsViewController`.
     
     - parameter viewController: `StepsViewController` instance, with which user is currently interacting.
     - parameter legIndex: Zero-based index of the `RouteLeg`, which contains the maneuver.
     - parameter stepIndex: Zero-based index of the `RouteStep`, which contains the maneuver.
     - parameter cell: `StepTableViewCell` instance, which visually represents primary, secondary and maneuver instructions.
     */
    func stepsViewController(_ viewController: StepsViewController, didSelect legIndex: Int, stepIndex: Int, cell: StepTableViewCell)
    
    /**
     Called when the user dismisses the `StepsViewController`.
     
     - parameter viewController: `StepsViewController` instance, which was dismissed.
     */
    func didDismissStepsViewController(_ viewController: StepsViewController)
}
