import UIKit

/// A banner view that contains the current step instruction along a route and responds to tap and swipe gestures.
open class StepInstructionsView: BaseInstructionsBannerView {}

/// `UITableViewCell` instance that provides the ability to show a current step instruction along a route.
open class StepTableViewCell: UITableViewCell {
    weak var instructionsView: StepInstructionsView!
    weak var separatorView: SeparatorView!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        commonInit()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        selectionStyle = .none

        setupViews()
        setupLayout()
    }

    override open func prepareForReuse() {
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
        let instructionsViewLeadingLayoutConstraint = instructionsView.leadingAnchor
            .constraint(equalTo: safeLeadingAnchor)
        let instructionsViewTrailingLayoutConstraint = instructionsView.trailingAnchor
            .constraint(equalTo: safeTrailingAnchor)
        let instructionsViewTopLayoutConstraint = instructionsView.topAnchor.constraint(equalTo: topAnchor)
        let instructionsViewBottomLayoutConstraint = instructionsView.bottomAnchor.constraint(equalTo: bottomAnchor)

        let instructionsViewLayoutConstrains = [
            instructionsViewLeadingLayoutConstraint,
            instructionsViewTrailingLayoutConstraint,
            instructionsViewTopLayoutConstraint,
            instructionsViewBottomLayoutConstraint,
        ]

        NSLayoutConstraint.activate(instructionsViewLayoutConstrains)

        NSLayoutConstraint.activate([
            separatorView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale),
            separatorView.leadingAnchor.constraint(equalTo: instructionsView.primaryLabel.leadingAnchor),
            separatorView.bottomAnchor.constraint(equalTo: instructionsView.bottomAnchor),
            separatorView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
        ])
    }
}
