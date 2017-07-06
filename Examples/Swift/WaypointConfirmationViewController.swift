import UIKit

protocol WaypointConfirmationViewControllerDelegate: NSObjectProtocol {
    func confirmationControllerDidConfirm(controller: WaypointConfirmationViewController)
}

class WaypointConfirmationViewController: UIViewController {

    weak var delegate: WaypointConfirmationViewControllerDelegate?

    @IBAction func continueButtonPressed(_ sender: Any) {
        delegate?.confirmationControllerDidConfirm(controller: self)
    }
}
