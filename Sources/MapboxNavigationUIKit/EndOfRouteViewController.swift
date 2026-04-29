import MapboxDirections
import MapboxNavigationCore
import UIKit

private enum ConstraintSpacing: CGFloat {
    case closer = 8.0
    case further = 65.0
}

private enum ContainerHeight: CGFloat {
    case normal = 200
    case commentShowing = 260
}

@_documentation(visibility: internal)
open class EndOfRouteContentView: UIView {}

@_documentation(visibility: internal)
open class EndOfRouteTitleLabel: StylableLabel {}

@_documentation(visibility: internal)
open class EndOfRouteStaticLabel: StylableLabel {}

@_documentation(visibility: internal)
open class EndOfRouteCommentView: StylableTextView {}

@_documentation(visibility: internal)
open class EndOfRouteButton: StylableButton {}

class EndOfRouteViewController: UIViewController {
    // MARK: IBOutlets

    @IBOutlet var labelContainer: UIView!
    @IBOutlet var staticYouHaveArrived: EndOfRouteStaticLabel!
    @IBOutlet var primary: UILabel!
    @IBOutlet var endNavigationButton: UIButton!
    @IBOutlet var stars: RatingControl!
    @IBOutlet var commentView: UITextView!
    @IBOutlet var commentViewContainer: UIView!
    @IBOutlet var showCommentView: NSLayoutConstraint!
    @IBOutlet var hideCommentView: NSLayoutConstraint!
    @IBOutlet var ratingCommentsSpacing: NSLayoutConstraint!

    // MARK: Properties

    lazy var placeholder: String = "END_OF_ROUTE_TITLE".localizedString(
        value: "How can we improve?",
        comment: "Comment Placeholder Text"
    )

    typealias DismissHandler = (Int, String?) -> Void
    var dismissHandler: DismissHandler?
    var comment: String?
    var rating: Int = 0 {
        didSet {
            rating == 0 ? hideComments() : showComments()
        }
    }

    open var destination: Waypoint? {
        didSet {
            guard isViewLoaded else { return }
            updateInterface()
        }
    }

    // MARK: Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        clearInterface()
        stars.didChangeRating = { [weak self] new in self?.rating = new }
        setPlaceholderText()
        styleCommentView()
        commentViewContainer.alpha = 0.0 // setting initial hidden state
        staticYouHaveArrived.text = "END_OF_ROUTE_ARRIVED".localizedString(
            value: "You have arrived",
            comment: "Title used for arrival"
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        preferredContentSize.height = height(for: .normal)
        updateInterface()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        rating == 0 ? hideComments() : showComments()
    }

    // MARK: IBActions

    @IBAction
    func endNavigationPressed(_ sender: Any) {
        dismissView()
    }

    // MARK: Private Functions

    private func styleCommentView() {
        commentView.layer.cornerRadius = 6.0
        commentView.layer.borderColor = UIColor.lightGray.cgColor
        commentView.layer.borderWidth = 1.0
        commentView.textContainerInset = UIEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
    }

    fileprivate func dismissView() {
        let dismissal: () -> Void = { self.dismissHandler?(self.rating, self.comment) }
        guard commentView.isFirstResponder else { return _ = dismissal() }
        commentView.resignFirstResponder()
        let fireTime = DispatchTime.now() + 0.3 // Not ideal, but works for now
        DispatchQueue.main.asyncAfter(deadline: fireTime, execute: dismissal)
    }

    private func showComments(animated: Bool = true) {
        showCommentView.isActive = true
        hideCommentView.isActive = false
        ratingCommentsSpacing.constant = ConstraintSpacing.closer.rawValue
        preferredContentSize.height = height(for: .commentShowing)

        let animate = {
            self.view.layoutIfNeeded()
            self.commentViewContainer.alpha = 1.0
            self.labelContainer.alpha = 0.0
        }

        let completion: (Bool) -> Void = { _ in self.labelContainer.isHidden = true }
        let noAnimate = { animate(); completion(true) }
        animated ? UIView.animate(withDuration: 0.3, animations: animate, completion: nil) : noAnimate()
    }

    private func hideComments(animated: Bool = true) {
        labelContainer.isHidden = false
        showCommentView.isActive = false
        hideCommentView.isActive = true
        ratingCommentsSpacing.constant = ConstraintSpacing.further.rawValue
        preferredContentSize.height = height(for: .normal)

        let animate = {
            self.view.layoutIfNeeded()
            self.commentViewContainer.alpha = 0.0
            self.labelContainer.alpha = 1.0
        }

        let completion: (Bool) -> Void = { _ in self.commentViewContainer.isHidden = true }
        let noAnimation = { animate(); completion(true) }
        animated ? UIView.animate(withDuration: 0.3, animations: animate, completion: nil) : noAnimation()
    }

    private func height(for height: ContainerHeight) -> CGFloat {
        let bottomMargin = view.safeAreaInsets.bottom
        return height.rawValue + bottomMargin
    }

    private func updateInterface() {
        guard let name = destination?.name?.nonEmptyString else { return styleForUnnamedDestination() }
        staticYouHaveArrived.isHidden = false
        primary.text = name
    }

    private func clearInterface() {
        primary.text = nil
        stars.rating = 0
    }

    private func styleForUnnamedDestination() {
        staticYouHaveArrived.isHidden = true
        primary.text = "END_OF_ROUTE_ARRIVED".localizedString(
            value: "You have arrived",
            comment: "Title used for arrival"
        )
    }

    private func setPlaceholderText() {
        commentView.text = placeholder
    }
}

// MARK: UITextViewDelegate

extension EndOfRouteViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard text.count == 1, text.rangeOfCharacter(from: CharacterSet.newlines) != nil else { return true }
        textView.resignFirstResponder()
        return false
    }

    func textViewDidChange(_ textView: UITextView) {
        comment = textView.text // Bind data model
    }

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == placeholder {
            textView.text = nil
            textView.alpha = 1.0
        }
        textView.becomeFirstResponder()
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if (textView.text?.isEmpty ?? true) == true {
            textView.text = placeholder
            textView.alpha = 0.9
        }
    }
}
