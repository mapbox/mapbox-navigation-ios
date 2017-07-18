import UIKit


class FeedbackViewController: UIViewController {
    
    typealias FeedbackSection = [FeedbackItem]
    
    struct FeedbackItem {
        var title: String
        var image: UIImage?
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
        
        let accident            = FeedbackItem(title: "Accident", image: nil)
        let hazard              = FeedbackItem(title: "Hazard", image: nil)
        let wrongInstruction    = FeedbackItem(title: "Wrong instruction", image: nil)
        let roadClosed          = FeedbackItem(title: "Road closed", image: nil)
        let unallowedTurn       = FeedbackItem(title: "Turn not allowed", image: nil)
        let other               = FeedbackItem(title: "Other", image: nil)
        
        sections = [
            [accident, hazard],
            [wrongInstruction, roadClosed],
            [unallowedTurn, other]
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
        cell.imageView.image = item.image
        
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return sections.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections[section].count
    }
}

extension FeedbackViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        abortAutodismiss()
    }
}

class FeedbackCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override var isSelected: Bool {
        didSet {
            backgroundColor = isSelected ? .blue : .clear
        }
    }
}

