import UIKit
import CoreGraphics

typealias RatingClosure = (Int) -> Void //rating

/*@IBDesignable*/
class RatingControl: UIStackView {
    
    //MARK: Constants
    static let defaultSize = CGSize(width: 32.0, height: 32.0)
    private let starTemplate = UIImage(named: "star", in: .mapboxNavigation, compatibleWith: nil)
    
    //MARK: Properties
    private var stars = [UIButton]()
    
    var didChangeRating: RatingClosure?
    
    var rating: Int = 0 {
        didSet {
            updateSelectionStates()
            didChangeRating?(rating)
        }
    }
    
    @objc dynamic public var selectedColor: UIColor = #colorLiteral(red: 0.1205472574, green: 0.2422055006, blue: 0.3489340544, alpha: 1) {
        didSet {
            updateSelectionStates()
        }
    }
    @objc dynamic public var normalColor: UIColor = #colorLiteral(red: 0.8508961797, green: 0.8510394692, blue: 0.850877285, alpha: 1) {
        didSet {
            updateSelectionStates()
        }
    }
    
    @objc dynamic public var starSize: CGSize = defaultSize {
        didSet {
            configureStars()
        }
    }
    
    @objc dynamic public var starCount: Int = 5 {
        didSet {
            configureStars()
        }
    }
    
    //MARK: Initializers
    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureStars()
    }
    
    required public init(coder: NSCoder) {
        super.init(coder: coder)
        configureStars()
    }
    
    //MARK: Private Functions
    private func configureStars() {
        removeStars()
        addStars()
        updateSelectionStates()
    }
    
    private func addStars() {
        for index in 0..<starCount {
            let button = UIButton(type: .custom)
            button.setImage(starTemplate, for: .normal)
            button.adjustsImageWhenHighlighted = false
            addButtonSizeConstraints(to: button)
            
            let setRatingNumber = NSNumber(value: index + 1)
            let setRatingString = NumberFormatter.localizedString(from: setRatingNumber, number: .none)
            let localizedString = NSLocalizedString("RATING_ACCESSIBILITY_SET", bundle: .mapboxNavigation, value: "Set %@ star rating", comment: "Accessibility Star Label")
            button.accessibilityLabel = String.localizedStringWithFormat(localizedString, setRatingString)
            
            button.addTarget(self, action: #selector(RatingControl.ratingButtonTapped(button:)), for: .touchUpInside)
            
            addArrangedSubview(button)
            
            stars.append(button)
        }
    }
    
    private func removeStars() {
        stars.forEach {
            removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        stars.removeAll()
    }
    
    private func updateSelectionStates() {
        for (index, button) in stars.enumerated() {
            
            let selected = index < rating
            button.tintColor = selected  ? selectedColor : normalColor
            button.isSelected = selected
            
            setAccessibility(for: button, at: index)
        }
    }
    
    private func setAccessibility(for button: UIButton, at index: Int) {
        setAccessibilityHint(for: button, at: index)
        
        let value: String
        
        switch rating {
        case 0:
            value = NSLocalizedString("NO_RATING", bundle: .mapboxNavigation, value: "No rating set.", comment: "No Rating Set")
        case 1:
            value = NSLocalizedString("RATING_1_STAR", bundle: .mapboxNavigation, value: "1 star set.", comment: "One Star Set")
        default:
            value = String.localizedStringWithFormat(NSLocalizedString("RATING_STARS_FORMAT", bundle: .mapboxNavigation, value: "%li stars set.", comment: "Format for rating stars set"), rating)
        }
        
        button.accessibilityValue = value
    }
    
    private func setAccessibilityHint(for button: UIButton, at index: Int) {
        guard rating == (index + 1) else { return } //This applies only to the zero-resettable button.
        
        button.accessibilityHint = NSLocalizedString("RATING_ACCESSIBILITY_RESET", bundle: .mapboxNavigation, value: "Tap to reset the rating to zero.", comment: "Rating Reset To Zero Accessability Hint")
    }
    
    
    private func addButtonSizeConstraints(to view: UIView) {
        view.widthAnchor.constraint(equalToConstant: starSize.width).isActive = true
        view.heightAnchor.constraint(equalToConstant: starSize.height).isActive = true
    }
    
    @objc private func ratingButtonTapped(button sender: UIButton) {
        guard let index = stars.index(of: sender) else { return assertionFailure("RatingControl.swift: The Star button that was tapped was not found in the RatingControl.stars array. This should never happen.") }
        let selectedRating = index + 1
        
        rating = (selectedRating == rating) ? 0 : selectedRating
    }
}
