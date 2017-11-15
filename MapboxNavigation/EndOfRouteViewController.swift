import UIKit
import MapboxDirections

class EndOfRouteViewController: UIViewController {

    @IBOutlet weak var primary: UILabel!
    @IBOutlet weak var secondary: UILabel!
    @IBOutlet weak var endNavigationButton: UIButton!
    @IBOutlet weak var stars: RatingControl!
    var rating: Int = 0
    var comments: String?
    
    var dismiss: (() -> Void)?
    lazy var geocoder: CLGeocoder = CLGeocoder()
    
    open var destination: Waypoint? {
        didSet {
            guard isViewLoaded else { return }
            updateInterface()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        stars.didChangeRating = { (new) in self.rating = new }
        updateInterface()
    }

    override func viewWillAppear(_ animated: Bool) {
        let path = UIBezierPath(roundedRect: view.bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 5, height: 5))
        let maskLayer = CAShapeLayer()
        maskLayer.path = path.cgPath
        view.layer.mask = maskLayer
    }

    
    @IBAction func endNavigationPressed(_ sender: Any) {
        dismiss?()
    }
    
    private func updateInterface() {
        primary.text = destination?.name
        guard let coordinate = destination?.coordinate else { return }
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { (places, error) in
            guard let city = places?.first?.locality, error == nil else { return self.secondary.text = nil }
            self.secondary.text = city
        }
    }
}
