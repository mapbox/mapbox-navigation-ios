import UIKit
import MapboxDirections

open class EndOfRouteViewController: UIViewController, DismissDraggable {
    
    //MARK: Outlets
    @IBOutlet weak var primary: UILabel!
    @IBOutlet weak var secondary: UILabel!
    
    @IBOutlet weak var stars: RatingControl!
    @IBOutlet weak var endNavigation: UIButton!
    
    
    //MARK: Properties
    var draggableHeight: CGFloat = 260.0
    
    var interactor = Interactor()
    var dismissal: (() -> Void)?
    
    lazy var geocoder: CLGeocoder = CLGeocoder()
    
    open var destination: Waypoint? {
        didSet {
            if (isViewLoaded) {
                updateInterface()
            }
        }
    }

    public static func loadFromStoryboard() -> EndOfRouteViewController {
        let storyboard = UIStoryboard(name: "Navigation", bundle: .mapboxNavigation)
        return storyboard.instantiateViewController(withIdentifier: String(describing: EndOfRouteViewController.self)) as! EndOfRouteViewController
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        clearInterface()
        enableDraggableDismiss()
        updateInterface()
    }
    
    override open func viewWillAppear(_ animated: Bool) {
        let path = UIBezierPath(roundedRect:view.bounds,
                                byRoundingCorners:[.topLeft, .topRight],
                                cornerRadii: CGSize(width: 5, height: 5))
        
        let maskLayer = CAShapeLayer()
        
        maskLayer.path = path.cgPath
        view.layer.mask = maskLayer
    }

    override open func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func endNavigationPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: dismissal)
    }
    
    //Mark: Interface
    private func updateInterface() {
        primary.text = destination?.name
        guard let coordinate = destination?.coordinate else { return }
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        geocoder.reverseGeocodeLocation(location) { (places, error) in
            guard let city = places?.first?.locality, error == nil else { return self.secondary.text = "" }
            self.secondary.text = city
        }
    }
    
    private func clearInterface() {
        [primary, secondary].forEach { $0.text = nil }
        stars.rating = 0
    }
    
    private func showTextField(animated: Bool = true) {
        
    }
    
    private func hideTextField(animated: Bool = true) {
        
    }
}

//MARK: - UIViewControllerTransitioning

extension EndOfRouteViewController: UIViewControllerTransitioningDelegate {
    public func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return DismissAnimator()
    }
    
    public func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return PresentAnimator()
    }
    
    public func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}
