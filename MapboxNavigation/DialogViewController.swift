import UIKit

class DialogViewController: UIViewController {
    
    @IBOutlet weak var dialogView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dialogView.layer.cornerRadius = 10
        imageView.tintColor = nil
        imageView.tintColor = .white
    }
    
    class func present(on viewController: UIViewController) {
        let storyboard = UIStoryboard(name: "Navigation", bundle: Bundle.mapboxNavigation   )
        let controller = storyboard.instantiateViewController(withIdentifier: "DialogViewController") as! DialogViewController
        
        controller.modalPresentationStyle = .overFullScreen
        controller.modalTransitionStyle = .crossDissolve
        
        viewController.present(controller, animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        perform(#selector(dismissAnimated), with: nil, afterDelay: 0.5)
    }
    
    @IBAction func dismissDialog(_ sender: UITapGestureRecognizer) {
        dismissAnimated()
    }
    
    @objc func dismissAnimated() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(dismissAnimated), object: nil)
        dismiss(animated: true, completion: nil)
    }
}
