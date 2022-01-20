import UIKit

/**
 A banner view that contains the current step instruction along a route and responds to tap and swipe gestures.
 */
open class StepInstructionsView: BaseInstructionsBannerView { }

/**
 `UITableViewCell` instance that provides the ability to show a current step instruction along a route.
 */
open class StepTableViewCell: UITableViewCell {

    weak var instructionsView: StepInstructionsView!
    weak var separatorView: SeparatorView!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        selectionStyle = .none
        
        setupViews()
        setupLayout()
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        instructionsView.update(for: nil)
    }
    
    func setupViews() {
        let instructionsView = StepInstructionsView()
        instructionsView.translatesAutoresizingMaskIntoConstraints = false
        instructionsView.separatorView.isHidden = true
        instructionsView.isUserInteractionEnabled = false
        addSubview(instructionsView)
        self.instructionsView = instructionsView
        
        let separatorView = SeparatorView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorView)
        self.separatorView = separatorView
    }
    
    func setupLayout() {
        // In case if iOS device has notch and is in `.landscapeRight` orientation - take into account
        // safe area, otherwise use just leading anchor. This is needed to prevent adding additional
        // spacing for `InstructionsView` in case if it's not really needed.
        let instructionsViewLeadingLayoutConstraint: NSLayoutConstraint
        if UIApplication.shared.statusBarOrientation == .landscapeRight {
            if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
                instructionsViewLeadingLayoutConstraint = instructionsView.leadingAnchor.constraint(equalTo: leadingAnchor)
            } else {
                instructionsViewLeadingLayoutConstraint = instructionsView.leadingAnchor.constraint(equalTo: safeLeadingAnchor)
            }
        } else {
            if UIApplication.shared.userInterfaceLayoutDirection == .rightToLeft {
                instructionsViewLeadingLayoutConstraint = instructionsView.leadingAnchor.constraint(equalTo: safeLeadingAnchor)
            } else {
                instructionsViewLeadingLayoutConstraint = instructionsView.leadingAnchor.constraint(equalTo: leadingAnchor)
            }
        }
        
        let instructionsViewTrailingLayoutConstraint = instructionsView.trailingAnchor.constraint(equalTo: safeTrailingAnchor)
        let instructionsViewTopLayoutConstraint = instructionsView.topAnchor.constraint(equalTo: topAnchor)
        let instructionsViewBottomLayoutConstraint = instructionsView.bottomAnchor.constraint(equalTo: bottomAnchor)
        
        let instructionsViewLayoutConstrains = [
            instructionsViewLeadingLayoutConstraint,
            instructionsViewTrailingLayoutConstraint,
            instructionsViewTopLayoutConstraint,
            instructionsViewBottomLayoutConstraint
        ]
        
        NSLayoutConstraint.activate(instructionsViewLayoutConstrains)
        
        NSLayoutConstraint.activate([
            separatorView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            separatorView.leadingAnchor.constraint(equalTo: instructionsView.primaryLabel.leadingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: instructionsView.bottomAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18)
        ])
    }
}
