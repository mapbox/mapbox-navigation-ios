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
        clearInterface()
        stars.didChangeRating = { (new) in self.rating = new }
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
        primary.text = destination?.name ?? string(for: destination?.coordinate)
        guard let coordinate = destination?.coordinate else { return }
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { (places, error) in
            guard let place = places?.first,
                  let city = place.locality,
                  let state = place.administrativeArea,
                  error == nil else { return self.secondary.text = nil }
            self.secondary.text = "\(city), \(state)"
        }
    }

private func clearInterface() {
    [primary, secondary].forEach { $0.text = nil }
    stars.rating = 0
}
    
    //FIXME: Temporary Placeholder
    private func string(for coordinate: CLLocationCoordinate2D?) -> String {
        guard let coordinate = coordinate else { return "Unknown" }
        return "\(coordinate.latitude),\(coordinate.longitude)"
    }
}
