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
        let storyboard = UIStoryboard(name: "Navigation", bundle: Bundle.navigationUI)
        let controller = storyboard.instantiateViewController(withIdentifier: "DialogViewController") as! DialogViewController
        
        controller.modalPresentationStyle = .overFullScreen
        controller.modalTransitionStyle = .crossDissolve
        
        viewController.present(controller, animated: true, completion: nil)
    }
    
    @IBAction func dismissDialog(_ sender: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }
}
