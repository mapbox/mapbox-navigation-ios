import CoreLocation
import UIKit
import MapboxCoreNavigation
import MapboxDirections

/**
 A banner view that contains the current step instruction and responds to tap and swipe gestures.
 
 This class responds and gets updated as the user progresses along a route according to the
 `NavigationComponent` and `BaseInstructionsBannerView` protocol.
*/
@IBDesignable
open class InstructionsBannerView: BaseInstructionsBannerView, NavigationComponent {
    
    /**
     Updates the instructions banner info as the user progresses along a route.
     
     - parameter service: The `NavigationService` instance that passes the instruction.
     - parameter instruction: The `VisualInstructionBanner` instance to be presented.
     - parameter routeProgress: The`RouteProgress` instance that the instruction banner view is updating.
     */
    public func navigationService(_ service: NavigationService,
                                  didPassVisualInstructionPoint instruction: VisualInstructionBanner,
                                  routeProgress: RouteProgress) {
        update(for: instruction)
    }
}

/**
 A banner view that contains the current step instruction along a route and responds to tap and
 swipe gestures, as the base of `InstructionsCardView` and `InstructionsBannerView`.
*/
open class BaseInstructionsBannerView: UIControl {
    
    /**
     A view that contains an image indicating a type of maneuver.
     */
    public weak var maneuverView: ManeuverView!
    
    /**
     A primary instruction label indicates the current step.
     */
    public weak var primaryLabel: PrimaryLabel!
    
    /**
     A secondary instruction label below the `PrimaryLabel`, which provides detailed information
     about the current step..
     */
    public weak var secondaryLabel: SecondaryLabel!
    
    /**
     A styled label indicates the remaining distance along the current step.
     */
    public weak var distanceLabel: DistanceLabel!
    
    /**
     A vertical view, which is used as a divider between `ManeuverView`/`DistanceLabel` views to the
     left and `PrimaryLabel`/`SecondaryLabel` views to the right.
     */
    public weak var dividerView: UIView!
    weak var _separatorView: UIView!
    
    /**
     An invisible helper view for visualizing the result of the constraints.
     */
    public weak var separatorView: SeparatorView!
    
    /**
     A vertical separator for the trailing side of the view.
     */
    var trailingSeparatorView: SeparatorView!
    
    /**
     A view, which indicates that there're more steps in the current route.
     
     If shown, `InstructionsBannerView` can be swiped to the bottom to see all of these remaining steps.
     */
    public weak var stepListIndicatorView: StepListIndicatorView!
    
    /**
     A `Boolean` value controls whether the banner view reponds to swipe gestures. Defaults to `false`.
     */
    @IBInspectable
    public var swipeable: Bool = false
    
    /**
     A `Boolean` value controls whether the banner view shows the `StepListIndicatorView`. Defaults to `true`.
     */
    @IBInspectable
    public var showStepIndicator: Bool = true {
        didSet {
            stepListIndicatorView.isHidden = !showStepIndicator
        }
    }
    
    /**
     The instruction banner view's delegate that conforms to `InstructionsBannerViewDelegate`.
     */
    public weak var delegate: InstructionsBannerViewDelegate? {
        didSet {
            if showStepIndicator {
                stepListIndicatorView.isHidden = false
            }
            primaryLabel.instructionDelegate = delegate
            secondaryLabel.instructionDelegate = delegate
        }
    }
    
    var centerYConstraints = [NSLayoutConstraint]()
    var baselineConstraints = [NSLayoutConstraint]()
    
    let distanceFormatter = DistanceFormatter()
    
    /**
     The remaining distance of current step in meters.
     */
    public var distance: CLLocationDistance? {
        didSet {
            distanceLabel.attributedDistanceString = nil
            
            if let distance = distance {
                distanceLabel.attributedDistanceString = distanceFormatter.attributedString(for: distance)
            } else {
                distanceLabel.text = nil
            }
        }
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        setupViews()
        setupLayout()
        centerYAlignInstructions()
        setupAvailableBounds()
        stepListIndicatorView.isHidden = !showStepIndicator
    }
    
    @objc func swipedInstructionBannerLeft(_ sender: Any) {
        guard swipeable && showStepIndicator else { return }

        if let gestureRecognizer = sender as? UISwipeGestureRecognizer,
           gestureRecognizer.state == .ended {
            if let delegate = delegate {
                delegate.didSwipeInstructionsBanner(self, swipeDirection: .left)
            }
        }
    }
    
    @objc func swipedInstructionBannerRight(_ sender: Any) {
        guard swipeable && showStepIndicator else { return }
        
        if let gestureRecognizer = sender as? UISwipeGestureRecognizer,
           gestureRecognizer.state == .ended {
            if let delegate = delegate {
                delegate.didSwipeInstructionsBanner(self, swipeDirection: .right)
            }
        }
    }
    
    @objc func swipedInstructionBannerDown(_ sender: Any) {
        guard showStepIndicator else { return }
        if let gestureRecognizer = sender as? UISwipeGestureRecognizer,
           gestureRecognizer.state == .ended {
            stepListIndicatorView.isHidden = !stepListIndicatorView.isHidden
            delegate?.didSwipeInstructionsBanner(self, swipeDirection: .down)
        }
    }
        
    @objc func tappedInstructionsBanner(_ sender: Any) {
        guard showStepIndicator else { return }
        if let delegate = delegate {
            stepListIndicatorView.isHidden = !stepListIndicatorView.isHidden
            delegate.didTapInstructionsBanner(self)
        }
    }
    
    /**
     Updates the instructions banner info with a given `VisualInstructionBanner`.
     
     - parameter instruction: The `VisualInstructionBanner` instance to be presented.
     */
    public func update(for instruction: VisualInstructionBanner?) {
        let secondaryInstruction = instruction?.secondaryInstruction
        primaryLabel.numberOfLines = secondaryInstruction == nil ? 2 : 1
        
        if secondaryInstruction == nil {
            centerYAlignInstructions()
        } else {
            baselineAlignInstructions()
        }
        
        primaryLabel.instruction = instruction?.primaryInstruction
        maneuverView.visualInstruction = instruction?.primaryInstruction
        maneuverView.drivingSide = instruction?.drivingSide ?? .right
        secondaryLabel.instruction = secondaryInstruction
    }
    
    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        maneuverView.isStart = true
        let component = VisualInstruction.Component.text(text: .init(text: "Primary text label",
                                                                     abbreviation: nil,
                                                                     abbreviationPriority: nil))
        let instruction = VisualInstruction(text: nil,
                                            maneuverType: .turn,
                                            maneuverDirection: .left,
                                            components: [component])
        primaryLabel.instruction = instruction
        
        distance = 100
    }
    
    /**
     Updates the instructions banner distance info for a given `RouteStepProgress`.
     
     - parameter currentStepProgress: The current `RouteStepProgress` instance that the instruction
     banner view is updating.
     */
    public func updateDistance(for currentStepProgress: RouteStepProgress) {
        let distanceRemaining = currentStepProgress.distanceRemaining
        distance = distanceRemaining > 5 ? distanceRemaining : 0
    }
    
    // MARK: Layout
    static let padding: CGFloat = 16
    static let maneuverViewSize = CGSize(width: 38, height: 38)
    static let stepListIndicatorViewSize = CGSize(width: 30, height: 5)
    
    func setupViews() {
        let maneuverView = ManeuverView()
        maneuverView.backgroundColor = .clear
        maneuverView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(maneuverView)
        self.maneuverView = maneuverView
        
        let distanceLabel = DistanceLabel()
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.adjustsFontSizeToFitWidth = true
        distanceLabel.minimumScaleFactor = 16.0 / 22.0
        addSubview(distanceLabel)
        self.distanceLabel = distanceLabel
        
        let primaryLabel = PrimaryLabel()
        primaryLabel.instructionDelegate = delegate
        primaryLabel.translatesAutoresizingMaskIntoConstraints = false
        primaryLabel.allowsDefaultTighteningForTruncation = true
        primaryLabel.adjustsFontSizeToFitWidth = true
        primaryLabel.numberOfLines = 1
        primaryLabel.minimumScaleFactor = 20.0 / 30.0
        primaryLabel.lineBreakMode = .byTruncatingTail
        addSubview(primaryLabel)
        self.primaryLabel = primaryLabel
        
        let secondaryLabel = SecondaryLabel()
        secondaryLabel.instructionDelegate = delegate
        secondaryLabel.translatesAutoresizingMaskIntoConstraints = false
        secondaryLabel.allowsDefaultTighteningForTruncation = true
        secondaryLabel.numberOfLines = 1
        secondaryLabel.minimumScaleFactor = 20.0 / 26.0
        secondaryLabel.lineBreakMode = .byTruncatingTail
        addSubview(secondaryLabel)
        self.secondaryLabel = secondaryLabel
        
        let dividerView = UIView()
        dividerView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(dividerView)
        self.dividerView = dividerView
        
        let _separatorView = UIView()
        _separatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(_separatorView)
        self._separatorView = _separatorView
        
        let separatorView = SeparatorView()
        separatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(separatorView)
        self.separatorView = separatorView
        
        let stepListIndicatorView = StepListIndicatorView()
        stepListIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stepListIndicatorView)
        self.stepListIndicatorView = stepListIndicatorView
        
        addTarget(self,
                  action: #selector(BaseInstructionsBannerView.tappedInstructionsBanner(_:)),
                  for: .touchUpInside)
        
        let swipeLeftGesture = UISwipeGestureRecognizer(target: self,
                                                        action: #selector(BaseInstructionsBannerView.swipedInstructionBannerLeft(_:)))
        swipeLeftGesture.direction = .left
        addGestureRecognizer(swipeLeftGesture)
        
        let swipeRightGesture = UISwipeGestureRecognizer(target: self,
                                                         action: #selector(BaseInstructionsBannerView.swipedInstructionBannerRight(_:)))
        swipeRightGesture.direction = .right
        addGestureRecognizer(swipeRightGesture)
        
        let swipeDownGesture = UISwipeGestureRecognizer(target: self,
                                                        action: #selector(BaseInstructionsBannerView.swipedInstructionBannerDown(_:)))
        swipeDownGesture.direction = .down
        addGestureRecognizer(swipeDownGesture)
        
        let trailingSeparatorView = SeparatorView()
        trailingSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(trailingSeparatorView)
        self.trailingSeparatorView = trailingSeparatorView
    }
    
    func setupLayout() {
        // firstColumnWidth is the width of the left side of the banner containing the maneuver view and distance label
        let firstColumnWidth = BaseInstructionsBannerView.maneuverViewSize.width + BaseInstructionsBannerView.padding * 3
        
        // Distance label
        distanceLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor,
                                               constant: BaseInstructionsBannerView.padding / 2).isActive = true
        distanceLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor,
                                                constant: -BaseInstructionsBannerView.padding / 2).isActive = true
        distanceLabel.centerXAnchor.constraint(equalTo: maneuverView.centerXAnchor,
                                               constant: 0).isActive = true
        distanceLabel.lastBaselineAnchor.constraint(equalTo: bottomAnchor,
                                                    constant: -BaseInstructionsBannerView.padding).isActive = true
        distanceLabel.topAnchor.constraint(greaterThanOrEqualTo: maneuverView.bottomAnchor).isActive = true
        
        // Turn arrow view
        maneuverView.heightAnchor.constraint(equalToConstant: BaseInstructionsBannerView.maneuverViewSize.height).isActive = true
        maneuverView.widthAnchor.constraint(equalToConstant: BaseInstructionsBannerView.maneuverViewSize.width).isActive = true
        maneuverView.topAnchor.constraint(equalTo: topAnchor,
                                          constant: BaseInstructionsBannerView.padding).isActive = true
        maneuverView.centerXAnchor.constraint(equalTo: leadingAnchor,
                                              constant: firstColumnWidth / 2).isActive = true
        
        // Primary Label
        primaryLabel.leadingAnchor.constraint(equalTo: dividerView.trailingAnchor).isActive = true
        primaryLabel.trailingAnchor.constraint(equalTo: trailingAnchor,
                                               constant: -18).isActive = true
        baselineConstraints.append(primaryLabel.topAnchor.constraint(equalTo: maneuverView.topAnchor,
                                                                     constant: -BaseInstructionsBannerView.padding / 2))
        centerYConstraints.append(primaryLabel.centerYAnchor.constraint(equalTo: centerYAnchor))
        
        // Secondary Label
        secondaryLabel.leadingAnchor.constraint(equalTo: dividerView.trailingAnchor).isActive = true
        secondaryLabel.trailingAnchor.constraint(equalTo: trailingAnchor,
                                                 constant: -18).isActive = true
        baselineConstraints.append(secondaryLabel.lastBaselineAnchor.constraint(equalTo: distanceLabel.lastBaselineAnchor,
                                                                                constant: -BaseInstructionsBannerView.padding / 2))
        baselineConstraints.append(secondaryLabel.topAnchor.constraint(greaterThanOrEqualTo: primaryLabel.bottomAnchor,
                                                                       constant: 0))
        centerYConstraints.append(secondaryLabel.topAnchor.constraint(greaterThanOrEqualTo: primaryLabel.bottomAnchor,
                                                                      constant: 0))
        
        // Drag Indicator View
        stepListIndicatorView.heightAnchor.constraint(equalToConstant: BaseInstructionsBannerView.stepListIndicatorViewSize.height).isActive = true
        stepListIndicatorView.widthAnchor.constraint(equalToConstant: BaseInstructionsBannerView.stepListIndicatorViewSize.width).isActive = true
        stepListIndicatorView.bottomAnchor.constraint(equalTo: bottomAnchor,
                                                      constant: -BaseInstructionsBannerView.padding / 2).isActive = true
        stepListIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        baselineConstraints.append(stepListIndicatorView.topAnchor.constraint(greaterThanOrEqualTo: secondaryLabel.bottomAnchor))
        centerYConstraints.append(stepListIndicatorView.topAnchor.constraint(greaterThanOrEqualTo: secondaryLabel.bottomAnchor,
                                                                             constant: 0))

        // Divider view (vertical divider between maneuver/distance to primary/secondary instruction
        dividerView.leadingAnchor.constraint(equalTo: leadingAnchor,
                                             constant: firstColumnWidth).isActive = true
        dividerView.widthAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        dividerView.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        dividerView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        // Separator view (invisible helper view for visualizing the result of the constraints)
        _separatorView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        _separatorView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        _separatorView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        _separatorView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        
        // Visible separator docked to the bottom
        separatorView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        separatorView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        separatorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        separatorView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        trailingSeparatorView.widthAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        trailingSeparatorView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        trailingSeparatorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        trailingSeparatorView.leadingAnchor.constraint(equalTo: trailingAnchor).isActive = true
    }
    
    // Aligns the instruction to the center Y (used for single line primary and/or secondary instructions)
    func centerYAlignInstructions() {
        _separatorView.isHidden = false
        baselineConstraints.forEach { $0.isActive = false }
        centerYConstraints.forEach { $0.isActive = true }
    }
    
    // Aligns primary top to the top of the maneuver view and the secondary baseline to the distance baseline (used for multiline)
    func baselineAlignInstructions() {
        _separatorView.isHidden = true
        centerYConstraints.forEach { $0.isActive = false }
        baselineConstraints.forEach { $0.isActive = true }
    }
    
    func setupAvailableBounds() {
        // Abbreviate if the instructions do not fit on one line
        primaryLabel.availableBounds = { [unowned self] in
            // Available width H:|-padding-maneuverView-padding-availableWidth-padding-|
            let availableWidth = self.primaryLabel.viewForAvailableBoundsCalculation?.bounds.width
            ?? self.bounds.width - BaseInstructionsBannerView.maneuverViewSize.width - BaseInstructionsBannerView.padding * 3
            return CGRect(x: 0, y: 0, width: availableWidth, height: self.primaryLabel.font.lineHeight)
        }
        
        secondaryLabel.availableBounds = { [unowned self] in
            // Available width H:|-padding-maneuverView-padding-availableWidth-padding-|
            let availableWidth = self.secondaryLabel.viewForAvailableBoundsCalculation?.bounds.width
            ?? self.bounds.width - BaseInstructionsBannerView.maneuverViewSize.width - BaseInstructionsBannerView.padding * 3
            return CGRect(x: 0, y: 0, width: availableWidth, height: self.secondaryLabel.font.lineHeight)
        }
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection == traitCollection { return }
        
        // Do not show trailing separator view in case of regular layout.
        if traitCollection.verticalSizeClass == .regular {
            trailingSeparatorView.isHidden = true
        } else {
            trailingSeparatorView.isHidden = false
        }
    }
}
