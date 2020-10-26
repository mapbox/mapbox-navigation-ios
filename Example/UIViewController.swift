import UIKit

extension UIViewController {
    
    func presentAlert(_ title: String? = nil, message: String? = nil, handler: ((UIAlertAction) -> Void)? = nil) {
        DispatchQueue.main.async {
            let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            let defaultHandler: ((UIAlertAction) -> Void) = { (action) in
                controller.dismiss(animated: true, completion: nil)
            }
            
            controller.addAction(UIAlertAction(title: NSLocalizedString("ALERT_OK", value: "OK", comment: "Alert action"), style: .default, handler: handler ?? defaultHandler))
            self.present(controller, animated: true, completion: nil)
        }
    }
}
