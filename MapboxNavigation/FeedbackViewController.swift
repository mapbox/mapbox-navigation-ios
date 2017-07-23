import UIKit


class FeedbackViewController: UIViewController {
    
    typealias FeedbackSection = [FeedbackItem]
    
    struct FeedbackItem {
        var title: String
        var image: UIImage?
        var backgroundColor: UIColor?
    }
    
    var sections = [FeedbackSection]()
    let cellReuseIdentifier = "collectionViewCellId"
    
    typealias SendFeedbackHandler = (FeedbackItem) -> ()
    
    var sendFeedbackHandler: SendFeedbackHandler?
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    class func loadFromStoryboard() -> FeedbackViewController {
        let storyboard = UIStoryboard(name: "Navigation", bundle: .mapboxNavigation)
        return storyboard.instantiateViewController(withIdentifier: "FeedbackViewController") as! FeedbackViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .clear
        containerView.applyDefaultCornerRadiusShadow(cornerRadius: 8)
        
        let colorOne = #colorLiteral(red: 0.9347146749, green: 0.5047877431, blue: 0.1419634521, alpha: 1)
        let colorTwo = #colorLiteral(red: 0.9823123813, green: 0.6965931058, blue: 0.1658670604, alpha: 1)
        
        let accidentImage       = Bundle.mapboxNavigation.image(named: "feedback_car_crash")?.withRenderingMode(.alwaysTemplate)
        let hazardImage         = Bundle.mapboxNavigation.image(named: "feedback_hazard")?.withRenderingMode(.alwaysTemplate)
        let roadClosedImage     = Bundle.mapboxNavigation.image(named: "feedback_road_closed")?.withRenderingMode(.alwaysTemplate)
        let unallowedTurnImage  = Bundle.mapboxNavigation.image(named: "feedback_turn_not_allowed")?.withRenderingMode(.alwaysTemplate)
        let routingImage        = Bundle.mapboxNavigation.image(named: "feedback_routing")?.withRenderingMode(.alwaysTemplate)
        let otherImage          = Bundle.mapboxNavigation.image(named: "feedback_other")?.withRenderingMode(.alwaysTemplate)
        
        let accident        = FeedbackItem(title: "Accident",           image: accidentImage,       backgroundColor: colorOne)
        let hazard          = FeedbackItem(title: "Hazard",             image: hazardImage,         backgroundColor: colorOne)
        let roadClosed      = FeedbackItem(title: "Road closed",        image: roadClosedImage,     backgroundColor: colorTwo)
        let unallowedTurn   = FeedbackItem(title: "Turn not allowed",   image: unallowedTurnImage,  backgroundColor: colorTwo)
        let routingError    = FeedbackItem(title: "Routing error",      image: routingImage,        backgroundColor: colorTwo)
        let other           = FeedbackItem(title: "Other",              image: otherImage,          backgroundColor: colorTwo)
        
        sections = [
            [accident, hazard],
            [roadClosed, unallowedTurn],
            [routingError, other]
        ]
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        perform(#selector(dismissFeedback), with: nil, afterDelay: 5)
    }
    
    @IBAction func sendFeedback(_ sender: Any) {
        abortAutodismiss()
        
        guard let selectedIndexPaths = collectionView.indexPathsForSelectedItems else {
            presentError("You have to select a type")
            return
        }
        guard let indexPath = selectedIndexPaths.first else {
            presentError("You have to select a type")
            return
        }
        
        let item = sections[indexPath.section][indexPath.row]
        sendFeedbackHandler?(item)
    }
    
    func presentError(_ message: String) {
        let controller = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            controller.dismiss(animated: true, completion: nil)
        }
        
        controller.addAction(action)
        present(controller, animated: true, completion: nil)
    }
    
    func abortAutodismiss() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(dismissFeedback), object: nil)
    }
    
    func dismissFeedback() {
        dismiss(animated: true, completion: nil)
    }
}

extension FeedbackViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellReuseIdentifier, for: indexPath) as! FeedbackCollectionViewCell
        let item = sections[indexPath.section][indexPath.row]
        
        cell.titleLabel.text = item.title
        cell.imageView.tintColor = .white
        cell.imageView.image = item.image
        cell.circleView.backgroundColor = item.backgroundColor
        
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[section].count
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        abortAutodismiss()
    }
}

extension FeedbackViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        abortAutodismiss()
    }
}

extension FeedbackViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.midX
        return CGSize(width: width, height: width * 0.75)
    }
}

class FeedbackCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var circleView: UIView!
    
    override func layoutSubviews() {
        super.layoutSubviews()
        circleView.layer.cornerRadius = circleView.bounds.midY
    }
    
    override var isSelected: Bool {
        didSet {
            backgroundColor = isSelected ? .blue : .clear
        }
    }
}

