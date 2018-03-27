import UIKit

class DialogViewController: UIViewController {
    enum Constants {
        static let dialogColor = UIColor.black.withAlphaComponent(0.8)
        static let dialogSize = CGSize(width: 260, height: 140)
        static let cornerRadius = CGFloat(10.0)
        static let labelFont = UIFont.systemFont(ofSize: 17.0)
        static let stackSpacing = CGFloat(20.0)
        static let checkmark = UIImage(named: "report_checkmark", in: .mapboxNavigation, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        static let labelText = NSLocalizedString("FEEDBACK_THANK_YOU", value: "Thank you for your report!", comment: "Message confirming that the user has successfully sent feedback")
    }
    
    lazy var dialogView: UIView = {
        let view: UIView = .forAutoLayout()
        view.backgroundColor = Constants.dialogColor
        view.layer.cornerRadius = Constants.cornerRadius
        return view
    }()
    
    lazy var imageView: UIImageView = {
        let view: UIImageView = .forAutoLayout()
        view.image = Constants.checkmark
        view.tintColor = .white
        return view
    }()
    
    lazy var label: UILabel = {
        let label: UILabel = .forAutoLayout()
        label.textColor = .white
        label.font = Constants.labelFont
        label.text = Constants.labelText
        return label
    }()
    
    lazy var stackView = UIStackView(orientation: .vertical,
                                     alignment: .center,
                                     distribution: .equalSpacing,
                                     spacing: Constants.stackSpacing,
                                     autoLayout: true)
    
    lazy var tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(DialogViewController.dismissAnimated))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
    }
    
    func setupViews() {
        view.addGestureRecognizer(tapRecognizer)
        view.addSubview(dialogView)
        dialogView.addSubview(stackView)
        stackView.addArrangedSubviews([imageView, label])
    }

    func setupConstraints() {
        let dialogWidth = dialogView.widthAnchor.constraint(equalToConstant: Constants.dialogSize.width)
        let dialogHeight = dialogView.heightAnchor.constraint(equalToConstant: Constants.dialogSize.height)
        let dialogCenterX = dialogView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        let dialogCenterY = dialogView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        let stackCenterX = stackView.centerXAnchor.constraint(equalTo: dialogView.centerXAnchor)
        let stackCenterY = stackView.centerYAnchor.constraint(equalTo: dialogView.centerYAnchor)
        
        let constraints = [dialogWidth, dialogHeight,
                           dialogCenterX, dialogCenterY,
                           stackCenterX, stackCenterY]
        NSLayoutConstraint.activate(constraints)
    }
    
    func present(on viewController: UIViewController) {
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
        
        viewController.present(self, animated: true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        perform(#selector(dismissAnimated), with: nil, afterDelay: 0.5)
    }
    
    @objc func dismissAnimated() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(dismissAnimated), object: nil)
        dismiss(animated: true, completion: nil)
    }
}
