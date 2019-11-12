import UIKit

extension UIViewController {
    func presentAlert(_ title: String? = nil, message: String? = nil) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: NSLocalizedString("ALERT_OK", value: "OK", comment: "Alert action"), style: .default, handler: { (action) in
            controller.dismiss(animated: true, completion: nil)
        }))
        present(controller, animated: true, completion: nil)
    }
}
