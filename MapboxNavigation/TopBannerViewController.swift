import Foundation
import UIKit
import MapboxCoreNavigation
import MapboxDirections

protocol TapSensitive: class {
    func didTap(_ source: TappableContainer)
}



class TopBannerViewController: ContainerViewController, TapSensitive {
    
    var purpleShown = false
    
    lazy open var topPaddingView: TopBannerView = .forAutoLayout()
    
    lazy open var purpleContainerView: TopBannerView = .forAutoLayout()
    
    lazy open var orangeContainerView: TopBannerView = .forAutoLayout()
    
    lazy open var orange: OrangeViewController = OrangeViewController(delegate: self)
    
    lazy open var purple: PurpleViewController = PurpleViewController(delegate: self)
    
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
        let constraints: [NSLayoutConstraint] = [
            purpleContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            purpleContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ]
        return constraints
    }()
    
    lazy var purpleHideConstraints: [NSLayoutConstraint] = {
        let constraints: [NSLayoutConstraint] = [
            orangeContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            purpleContainerView.bottomAnchor.constraint(equalTo: orangeContainerView.bottomAnchor)
        ]
        return constraints
    }()
    
    lazy var purpleShowConstraints: [NSLayoutConstraint] = {
        let constraints: [NSLayoutConstraint] = [
            purpleContainerView.topAnchor.constraint(equalTo: orangeContainerView.bottomAnchor),
            purpleContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        return constraints
    }()

    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addSubviews()
        
        embed(orange, in: orangeContainerView) { (parent, child) -> [NSLayoutConstraint] in
            child.view.translatesAutoresizingMaskIntoConstraints = false
            return self.orange.view.constraintsForPinning(to: self.orangeContainerView)
        }
        
        embed(purple, in: purpleContainerView)  { (parent, child) -> [NSLayoutConstraint] in
            child.view.translatesAutoresizingMaskIntoConstraints = false
            return self.purple.view.constraintsForPinning(to: self.purpleContainerView)
        }
        
        setConstraints()
        
        topPaddingView.backgroundColor = .green
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        UIApplication.shared.delegate!.window!!.layer.speed = 0.1
        
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
        view.layoutIfNeeded()
        print("Frame! \(purpleContainerView.frame)")
//        dropDownAnimation(view: purpleContainerView)
        NSLayoutConstraint.deactivate(purpleHideConstraints)
        NSLayoutConstraint.activate(purpleShowConstraints)
        
        UIView.animate(withDuration: 1.0) {
            self.view.layoutIfNeeded()
        }
        
    }
    
    func hidePurple() {
        view.layoutIfNeeded()
        NSLayoutConstraint.deactivate(purpleShowConstraints)
        NSLayoutConstraint.activate(purpleHideConstraints)
        
        UIView.animate(withDuration: 1.0, animations: view.superview!.layoutIfNeeded)// ?? view.layoutIfNeeded)
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
        view.backgroundColor = .orange
        view.heightAnchor.constraint(equalToConstant: 100).isActive = true
    }
}

class PurpleViewController: TappableContainer {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .purple
        view.heightAnchor.constraint(equalToConstant: 200).isActive = true
        
        let image = UIImage(named: "80px-I-280", in: .mapboxNavigation, compatibleWith: nil)
        let imageView = UIImageView(image: image)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)
        
        let constraints = [
            imageView.heightAnchor.constraint(equalToConstant: 100),
            imageView.widthAnchor.constraint(equalToConstant: 100),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        
        NSLayoutConstraint.activate(constraints)
        view.layoutIfNeeded()
        
    }
}
