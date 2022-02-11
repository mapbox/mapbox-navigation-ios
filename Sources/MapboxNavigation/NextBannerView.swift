import UIKit
import MapboxDirections
import MapboxCoreNavigation

/// :nodoc:
open class NextInstructionLabel: InstructionLabel {}

/// :nodoc:
@IBDesignable
open class NextBannerView: UIView, NavigationComponent {
    
    weak var maneuverView: ManeuverView!
    weak var instructionLabel: NextInstructionLabel!
    weak var bottomSeparatorView: SeparatorView!
    weak var instructionDelegate: VisualInstructionDelegate? {
        didSet {
            instructionLabel.instructionDelegate = instructionDelegate
        }
    }
    public var isCurrentlyVisible: Bool = false
    private var shouldHide: Bool = false
    private var shouldShow: Bool = false
    private var isAnimating: Bool = false
    
    /**
     A vertical separator for the trailing side of the view.
     */
    var trailingSeparatorView: SeparatorView!
    
    /**
     A closure that is called after either presenting or dismissing next banner view.
     
     - parameter completed: Boolean value that indicates whether or not the animation actually
     finished before the completion handler was called.
     */
    public typealias CompletionHandler = (_ completed: Bool) -> Void
    
    override init(frame: CGRect) {
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
    }
    
    func setupViews() {
        translatesAutoresizingMaskIntoConstraints = false
        
        let maneuverView = ManeuverView()
        maneuverView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(maneuverView)
        self.maneuverView = maneuverView
        
        let instructionLabel = NextInstructionLabel()
        instructionLabel.instructionDelegate = instructionDelegate
        instructionLabel.shieldHeight = instructionLabel.font.pointSize
        instructionLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(instructionLabel)
        self.instructionLabel = instructionLabel
        
        instructionLabel.availableBounds = { [unowned self] in
            // Available width H:|-padding-maneuverView-padding-availableWidth-padding-|
            let availableWidth = self.bounds.width - BaseInstructionsBannerView.maneuverViewSize.width - BaseInstructionsBannerView.padding * 3
            return CGRect(x: 0, y: 0, width: availableWidth, height: self.instructionLabel.font.lineHeight)
        }
        
        let bottomSeparatorView = SeparatorView()
        bottomSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bottomSeparatorView)
        self.bottomSeparatorView = bottomSeparatorView
        
        let trailingSeparatorView = SeparatorView()
        trailingSeparatorView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(trailingSeparatorView)
        self.trailingSeparatorView = trailingSeparatorView
        
        trailingSeparatorView.widthAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        trailingSeparatorView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        trailingSeparatorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        trailingSeparatorView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        
        clipsToBounds = true
    }
    
    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        maneuverView.isEnd = true
        let component = VisualInstruction.Component.text(text: .init(text: "Next step", abbreviation: nil, abbreviationPriority: nil))
        let instruction = VisualInstruction(text: nil, maneuverType: .turn, maneuverDirection: .right, components: [component])
        instructionLabel.instruction = instruction
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection == traitCollection { return }
        
        updateTrailingSeparatorView()
    }
    
    func updateTrailingSeparatorView() {
        // Do not show trailing separator view in case of regular layout.
        if traitCollection.verticalSizeClass == .regular {
            trailingSeparatorView.isHidden = true
        } else {
            trailingSeparatorView.isHidden = false
        }
    }
    
    func setupLayout() {
        let heightConstraint = heightAnchor.constraint(equalToConstant: 40)
        heightConstraint.priority = UILayoutPriority(rawValue: 999)
        heightConstraint.isActive = true
        
        let midX = BaseInstructionsBannerView.padding + BaseInstructionsBannerView.maneuverViewSize.width / 2
        maneuverView.centerXAnchor.constraint(equalTo: leadingAnchor, constant: midX).isActive = true
        maneuverView.heightAnchor.constraint(equalToConstant: 22).isActive = true
        maneuverView.widthAnchor.constraint(equalToConstant: 22).isActive = true
        maneuverView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        
        instructionLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 70).isActive = true
        instructionLabel.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        instructionLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
        
        bottomSeparatorView.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
        bottomSeparatorView.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        bottomSeparatorView.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        bottomSeparatorView.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
    }
    
    public func navigationService(_ service: NavigationService,
                                  didPassVisualInstructionPoint instruction: VisualInstructionBanner,
                                  routeProgress: RouteProgress) {
        guard shouldShowNextBanner(for: routeProgress) else {
            hide()
            return
        }
        
        update(for: instruction)
    }
    
    func shouldShowNextBanner(for routeProgress: RouteProgress) -> Bool {
        let durationForNext = RouteControllerHighAlertInterval * RouteControllerLinkedInstructionBufferMultiplier
        
        guard let upcomingStep = routeProgress.currentLegProgress.upcomingStep,
              routeProgress.currentLegProgress.currentStepProgress.durationRemaining <= durationForNext,
              upcomingStep.expectedTravelTime <= durationForNext,
              let _ = upcomingStep.instructionsDisplayedAlongStep?.last else {
                  return false
              }
        
        return true
    }
    
    /**
     Updates the instructions banner info with a given `VisualInstructionBanner`.
     
     - parameter visualInstruction: Current instruction, which will be displayed in the next banner view.
     - parameter animated: If `true`, next banner view presentation or dismissal is animated.
     - parameter duration: Duration of the animation (in seconds). In case if `animated` parameter
     is set to `false` this value is ignored.
     - parameter completion: A completion handler that will be called once next banner view is either shown or hidden.
     */
    public func update(for visualInstruction: VisualInstructionBanner?,
                       animated: Bool = true,
                       duration: TimeInterval = 0.5,
                       completion: CompletionHandler? = nil) {
        guard let tertiaryInstruction = visualInstruction?.tertiaryInstruction,
              tertiaryInstruction.laneComponents.isEmpty else {
                  hide(animated: animated,
                       duration: duration) { completed in
                      completion?(completed)
                  }
                  return
              }
        
        maneuverView.visualInstruction = tertiaryInstruction
        maneuverView.drivingSide = visualInstruction?.drivingSide ?? .right
        instructionLabel.instruction = tertiaryInstruction
        show(animated: animated,
             duration: duration) { completed in
            completion?(completed)
        }
        updateTrailingSeparatorView()
    }
    
    /**
     Shows next banner view.
     
     - parameter animated: If `true`, next banner view presentation is animated. Defaults to `true`.
     - parameter duration: Duration of the animation (in seconds). In case if `animated` parameter
     is set to `false` this value is ignored.
     - parameter completion: A completion handler that will be called once next banner is shown.
     */
    public func show(animated: Bool = true,
                     duration: TimeInterval = 0.5,
                     completion: CompletionHandler? = nil) {
        guard isHidden, !isCurrentlyVisible else {
            completion?(true)
            return
        }
        
        if animated {
            shouldShow = true
            
            if !isAnimating {
                isAnimating = true
                
                UIView.defaultAnimation(duration, animations: {
                    self.isCurrentlyVisible = true
                    self.isHidden = false
                }) { completed in
                    self.shouldShow = false
                    self.isAnimating = false
                    
                    if self.shouldHide {
                        self.hide()
                    }
                    
                    completion?(completed)
                }
            } else {
                completion?(true)
            }
        } else {
            isHidden = false
            isCurrentlyVisible = true
            completion?(true)
        }
    }
    
    /**
     Hides next banner view.
     
     - parameter animated: If `true`, next banner view dismissal is animated. Defaults to `true`.
     - parameter duration: Duration of the animation (in seconds). In case if `animated` parameter
     is set to `false` this value is ignored.
     - parameter completion: A completion handler that will be called after next banner view dismissal.
     */
    public func hide(animated: Bool = true,
                     duration: TimeInterval = 0.5,
                     completion: CompletionHandler? = nil) {
        guard !isHidden, isCurrentlyVisible else {
            completion?(true)
            return
        }
        
        if animated {
            shouldHide = true
            
            if !isAnimating {
                isAnimating = true
                
                UIView.defaultAnimation(duration, animations: {
                    self.isCurrentlyVisible = false
                    self.isHidden = true
                }) { completed in
                    self.shouldHide = false
                    self.isAnimating = false
                    
                    if self.shouldShow {
                        self.show()
                    }
                    
                    completion?(completed)
                }
            } else {
                completion?(true)
            }
        } else {
            isHidden = true
            isCurrentlyVisible = false
            completion?(true)
        }
    }
}
