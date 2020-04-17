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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
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
    }
    
    override open func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        maneuverView.isEnd = true
        let component = VisualInstruction.Component.text(text: .init(text: "Next step", abbreviation: nil, abbreviationPriority: nil))
        let instruction = VisualInstruction(text: nil, maneuverType: .turn, maneuverDirection: .right, components: [component])
        instructionLabel.instruction = instruction
    }
    
    func setupLayout() {
        let heightConstraint = heightAnchor.constraint(equalToConstant: 44)
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
    
    public func navigationService(_ service: NavigationService, didPassVisualInstructionPoint instruction: VisualInstructionBanner, routeProgress: RouteProgress) {
        guard shouldShowNextBanner(for: routeProgress) else {
            hide()
            return
        }

        update(for: instruction)
    }
    
    func shouldShowNextBanner(for routeProgress: RouteProgress) -> Bool {
        guard let upcomingStep = routeProgress.currentLegProgress.upcomingStep else {
            return false
        }
        
        let durationForNext = RouteControllerHighAlertInterval * RouteControllerLinkedInstructionBufferMultiplier
        
        guard routeProgress.currentLegProgress.currentStepProgress.durationRemaining <= durationForNext, upcomingStep.expectedTravelTime <= durationForNext else {
            return false
        }
        guard let _ = upcomingStep.instructionsDisplayedAlongStep?.last else {
            return false
        }
        
        return true
    }
            
    /**
     Updates the instructions banner info with a given `VisualInstructionBanner`.
     */
    public func update(for visualInstruction: VisualInstructionBanner?) {
        guard let tertiaryInstruction = visualInstruction?.tertiaryInstruction, tertiaryInstruction.laneComponents.isEmpty else {
            hide()
            return
        }
        
        maneuverView.visualInstruction = tertiaryInstruction
        maneuverView.drivingSide = visualInstruction?.drivingSide ?? .right
        instructionLabel.instruction = tertiaryInstruction
        show()
    }
    
    public func show() {
        guard isHidden, !isCurrentlyVisible else { return }
        UIView.defaultAnimation(0.3, animations: {
            self.isCurrentlyVisible = true
            self.isHidden = false
        }, completion: nil)
    }
    
    public func hide() {
        guard !isHidden, isCurrentlyVisible else { return }
        UIView.defaultAnimation(0.3, animations: {
            self.isCurrentlyVisible = false
            self.isHidden = true
        }, completion: nil)
    }
}
