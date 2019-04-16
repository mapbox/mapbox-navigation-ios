import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxDirections

protocol TapSensitive: class {
    func didTap(_ source: TappableContainer)
}



class TopBannerViewController: ContainerViewController, TapSensitive {
    
    var purpleShown = false
    
    lazy open var topPaddingView: TopBannerView =  {
        let view: TopBannerView = .forAutoLayout()
        view.accessibilityIdentifier = "topPaddingView"
        return view
        }()
    
    lazy open var purpleContainerView: TopBannerView = {
        let view: TopBannerView = .forAutoLayout()
        view.accessibilityIdentifier = "purpleContainerView"
        return view
    }()
    
    lazy open var orangeContainerView: TopBannerView = {
        let view: TopBannerView = .forAutoLayout()
        view.accessibilityIdentifier = "orangeContainerView"
        return view
    }()
    
    lazy open var orange: OrangeViewController = {
       let vc = OrangeViewController(delegate: self)
        vc.view.accessibilityIdentifier = "orange"
        return vc
    }()
    
    lazy open var purple: PurpleViewController = {
       let vc = PurpleViewController(delegate: self)
        vc.view.accessibilityIdentifier = "purple"
        return vc
    }()
    
    var currentChild: TappableContainer?
    
    
    
    lazy var orangeContainerConstraints: [NSLayoutConstraint] = {
        let constraints: [NSLayoutConstraint] = [
            orangeContainerView.topAnchor.constraint(equalTo: topPaddingView.bottomAnchor),
            orangeContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            orangeContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        return constraints
    }()
    
    lazy var purpleContainerConstraints: [NSLayoutConstraint] = {
        return [
            purpleContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            purpleContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ]
    }()
    
    lazy var purpleHideConstraints: [NSLayoutConstraint] = {
        return [
            //orangeContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            //purpleContainerView.topAnchor.constraint
            purpleContainerView.bottomAnchor.constraint(equalTo: orangeContainerView.bottomAnchor)
        ]
    }()
    
    lazy var purpleShowConstraints: [NSLayoutConstraint] = {
        return [
            purpleContainerView.topAnchor.constraint(equalTo: orangeContainerView.bottomAnchor),
            view.bottomAnchor.constraint(equalTo: self.parent!.view.bottomAnchor)
            //purpleContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
    }()
    
//    lazy var bottomConstraint: NSLayoutConstraint = {
//        return view.bottomAnchor.constraint(equalTo: orangeContainerView.bottomAnchor)
//    }()
    var bottomConstraint: NSLayoutConstraint?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "topBannerRoot"
        addSubviews()
        topPaddingView.accessibilityIdentifier = "green"
        embed(orange, in: orangeContainerView) { (parent, child) -> [NSLayoutConstraint] in
            child.view.translatesAutoresizingMaskIntoConstraints = false
            return self.orange.view.constraintsForPinning(to: self.orangeContainerView)
        }
        view.clipsToBounds = false
//        embed(purple, in: purpleContainerView)  { (parent, child) -> [NSLayoutConstraint] in
//            child.view.translatesAutoresizingMaskIntoConstraints = false
//            //return self.purple.view.constraintsForPinning(to: self.purpleContainerView)
//            return nil
//        }
        embed(purple, in: purpleContainerView)
        purpleContainerView.translatesAutoresizingMaskIntoConstraints = false
        purple.view.pinInSuperview()
        
        setConstraints()
        
        topPaddingView.backgroundColor = .green
        
        NSLayoutConstraint.deactivate(purpleShowConstraints)
        NSLayoutConstraint.activate(purpleHideConstraints)
        
        bottomConstraint = view.bottomAnchor.constraint(equalTo: orangeContainerView.bottomAnchor)
        bottomConstraint?.isActive = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        //UIApplication.shared.delegate!.window!!.layer.speed = 0.1
        
        super.viewDidAppear(animated)
    }
    
    func addSubviews() {
        [orangeContainerView, purpleContainerView, topPaddingView].forEach(view.addSubview(_:))
        view.sendSubviewToBack(purpleContainerView)
    }
    
    func setConstraints() {
        let constraints: [NSLayoutConstraint] = [
            topPaddingView.topAnchor.constraint(equalTo: view.topAnchor),
            topPaddingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topPaddingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topPaddingView.bottomAnchor.constraint(equalTo: view.safeTopAnchor),
            
        ]
        
        NSLayoutConstraint.activate(constraints + purpleContainerConstraints + orangeContainerConstraints + purpleHideConstraints)
    }
    
    func embed(_ child: UIViewController, in container: UIView, constrainedBy constraints: ((UIViewController, UIViewController) -> [NSLayoutConstraint])? = nil) {
        child.willMove(toParent: self)
        addChild(child)
        container.addSubview(child.view)
        if let childConstraints: [NSLayoutConstraint] = constraints?(self, child) {
            view.addConstraints(childConstraints)
        }
        child.didMove(toParent: self)
    }
    
    
    func showPurple() {
        
        print("Frame! \(purpleContainerView.frame)")
        
        NSLayoutConstraint.deactivate(purpleHideConstraints)
        NSLayoutConstraint.activate(purpleShowConstraints)
        
        bottomConstraint?.isActive = false
        bottomConstraint = view.bottomAnchor.constraint(equalTo: purpleContainerView.bottomAnchor)
        bottomConstraint?.isActive = true
        parent?.view.setNeedsLayout()
        UIView.animate(withDuration: 1) { [weak self] in
            self?.parent?.view.layoutIfNeeded()
        }
    }
    
    func hidePurple() {
        
        NSLayoutConstraint.deactivate(purpleShowConstraints)
        NSLayoutConstraint.activate(purpleHideConstraints)
        bottomConstraint?.isActive = false
        bottomConstraint = view.bottomAnchor.constraint(equalTo: orangeContainerView.bottomAnchor)
        bottomConstraint?.isActive = true
        
        parent?.view.setNeedsLayout()
        UIView.animate(withDuration: 1) { [weak self] in
            self?.parent?.view.layoutIfNeeded()
        }
    }
    
    public func dropDownAnimation(view: UIView) {
//        var frame = view.frame
//        view.frame = frame
//        let increased =  self.view.frame.size.height + view.frame.height
        
        print("Before! Purple: \(view.frame), superview: \(self.view.frame)") //, height should be: \(increased)")
//        setFrameSize(to: increased)
        
        UIView.animate(withDuration: 0.35, delay: 0, options: [.beginFromCurrentState, .curveEaseOut], animations: {
            var frame = view.frame
            frame.origin.y += frame.height
            view.frame = frame
        }) { _ in
            print("After! Purple: \(view.frame), superview: \(self.view.frame)")
        }
    }
    
    func setFrameSize(to height: CGFloat) {
        self.view.superview!.frame.size.height = height
    }
 
    public func slideUpAnimation(completion: CompletionHandler? = nil, view: UIView) {
        UIView.animate(withDuration: 0.35, delay: 0, options: [.beginFromCurrentState, .curveEaseIn], animations: {
            var frame = view.frame
            frame.origin.y -= frame.height
            view.frame = frame
        }) { (completed) in
            completion?()
        }
    }
    
    
    func didTap(_ source: TappableContainer) {
        if source == orange {
            showPurple()
        } else {
            hidePurple()
        }
    }
}

class TappableContainer: ContainerViewController {
    lazy var tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
    weak var delegate: TapSensitive?
    
    convenience init(delegate: TapSensitive) {
        self.init(nibName: nil, bundle: nil)
        self.delegate = delegate
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func didTap(_ recognizer: UIGestureRecognizer) {
        delegate?.didTap(self)
    }
    
}

class OrangeViewController: TappableContainer {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "orange"
        view.backgroundColor = .orange
        view.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }
}

class PurpleViewController: TappableContainer {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "purple"
        view.backgroundColor = .purple
//        view.heightAnchor.constraint(equalToConstant: 200).isActive = true
    }
}
