import UIKit


class EndOfRouteViewController: UIViewController {

    @IBOutlet weak var primary: UILabel!
    @IBOutlet weak var secondary: UILabel!
    @IBOutlet weak var endNavigationButton: UIButton!
    @IBOutlet weak var stars: RatingControl!
    var rating: Int = 0
    var comments: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        stars.didChangeRating = { (new) in self.rating = new }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let path = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 5, height: 5))
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        view.layer.mask = maskLayer
    }

    var dismiss: (() -> Void)?
    
    @IBAction func endNavigationPressed(_ sender: Any) {
        dismiss?()
    }
}
