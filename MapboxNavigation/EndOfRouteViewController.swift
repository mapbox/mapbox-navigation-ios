import UIKit
import MapboxDirections

enum ConstraintSpacing: CGFloat {
    case closer = 16.0
    case further = 45.0
}

class EndOfRouteViewController: UIViewController {

    @IBOutlet weak var primary: UILabel!
    @IBOutlet weak var secondary: UILabel!
    @IBOutlet weak var endNavigationButton: UIButton!
    @IBOutlet weak var stars: RatingControl!
    @IBOutlet weak var commentView: UITextView!
    @IBOutlet weak var showCommentView: NSLayoutConstraint!
    @IBOutlet weak var hideCommentView: NSLayoutConstraint!
    @IBOutlet weak var ratingCommentsSpacing: NSLayoutConstraint!
    
    var rating: Int = 0 {
        didSet {
            rating == 0 ? hideComments() : showComments()
        }
    }
    var comment: String?
    
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
    
    private func showComments(animated: Bool = true) {
        showCommentView.isActive = true
        hideCommentView.isActive = false
        ratingCommentsSpacing.constant = ConstraintSpacing.closer.rawValue
        
        let layout = view.layoutIfNeeded
        
        animated ? UIView.animate(withDuration: 0.3, animations: layout) : layout()
    }
    
    private func hideComments(animated: Bool = true) {
        showCommentView.isActive = false
        hideCommentView.isActive = true
        ratingCommentsSpacing.constant = ConstraintSpacing.further.rawValue
        
        let layout = view.layoutIfNeeded
        
        animated ? UIView.animate(withDuration: 0.3, animations: layout) : layout()
    }
    
    
    private func updateInterface() {
        primary.text = string(for: destination)
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
    private func string(for destination: Waypoint?) -> String {
        guard let destination = destination else { return "Unknown" }
        guard destination.name?.isEmpty ?? false else { return destination.name! }
        let coord = destination.coordinate
        return String(format: "%2f", coord.latitude) + "," + String(format: "%2f", coord.longitude)
    }
}
