import CoreLocation
import UIKit
import MapboxDirections

/**
 A container view for the information currently displayed in `InstructionsCardViewController`.
 */
public class InstructionsCardContainerView: StylableView, InstructionsCardContainerViewDelegate {
    
    enum State {
        case unhighlighted
        case highighted
    }
    
    // MARK: Child Views Configuration
    
    /**
     Color of the background that will be used in case if distance to the next maneuver is higher
     than threshold distance, defined in `InstructionCardHighlightDistance`.
     */
    @objc dynamic public var customBackgroundColor: UIColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    
    /**
     Color of the background that will be used when remaining distance to the next maneuver is below
     threshold distance, defined in `InstructionCardHighlightDistance`.
     */
    @objc dynamic public var highlightedBackgroundColor: UIColor = #colorLiteral(red: 0.26, green: 0.39, blue: 0.98, alpha: 1.0)
    
    /**
     Color of the separator between `InstructionsCardView` or `LanesView`/`NextBannerView`.
     */
    @objc dynamic public var separatorColor: UIColor = #colorLiteral(red: 0.737254902, green: 0.7960784314, blue: 0.8705882353, alpha: 1)
    
    /**
     Color of the separator between `InstructionsCardView` or `LanesView`/`NextBannerView` that will
     be used when remaining distance to the next maneuver is below threshold distance, defined in
     `InstructionCardHighlightDistance`.
     */
    @objc dynamic public var highlightedSeparatorColor: UIColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    
    /**
     Vertical stack view that contains `InstructionsCardView`, `LanesView` and `NextBannerView`.
     */
    lazy var informationStackView = UIStackView(orientation: .vertical, autoLayout: true)
    lazy var instructionsCardView: InstructionsCardView = .forAutoLayout()
    lazy var lanesView: LanesView = .forAutoLayout(hidden: true)
    lazy var nextBannerView: NextBannerView = .forAutoLayout(hidden: true)
    
    /**
     State of the instructions card view.
     */
    var state: InstructionsCardContainerView.State = .unhighlighted {
        didSet {
            updateInstructionsCardContainerView(for: state)
            updateInstructionsCardView(for: state)
            updateLanesView(for: state)
            updateNextBannerView(for: state)
        }
    }

    // MARK: Updating the Instructions
    
    /**
     Delegate, which provides methods that allow presented visual instructions customization
     within the instructions container view.
     */
    public weak var delegate: InstructionsCardContainerViewDelegate?
    
    public required init() {
        super.init(frame: .zero)
        commonInit()
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        commonInit()
    }

    public func updateInstruction(for step: RouteStep,
                                  distance: CLLocationDistance,
                                  instruction: VisualInstructionBanner? = nil,
                                  isCurrentCardStep: Bool = false) {
        instructionsCardView.updateDistanceFromCurrentLocation(distance)
        instructionsCardView.step = step
        
        if let instruction = instruction ?? step.instructionsDisplayedAlongStep?.last {
            updateInstruction(instruction)
        }
        updateInstructionCard(distance: distance, isCurrentCardStep: isCurrentCardStep)
    }
    
    public func updateInstruction(_ instruction: VisualInstructionBanner) {
        // In case of instruction cards these views should be always hidden.
        instructionsCardView.stepListIndicatorView.isHidden = true
        lanesView.trailingSeparatorView.isHidden = true
        nextBannerView.trailingSeparatorView.isHidden = true
        
        // By default only `InstructionsCardView` is visible.
        instructionsCardView.separatorView.isHidden = true
        lanesView.separatorView.isHidden = true
        nextBannerView.bottomSeparatorView.isHidden = true
        
        instructionsCardView.update(for: instruction)
        lanesView.update(for: instruction, animated: false)
        
        nextBannerView.instructionDelegate = self
        nextBannerView.update(for: instruction, animated: false)
        
        if let tertiaryInstruction = instruction.tertiaryInstruction {
            if tertiaryInstruction.laneComponents.isEmpty {
                instructionsCardView.separatorView.isHidden = false
            } else {
                instructionsCardView.separatorView.isHidden = false
            }
        }
    }
    
    public func updateInstructionCard(distance: CLLocationDistance, isCurrentCardStep: Bool = false) {
        // In case if instruction card is the closest one to the next maneuver and if distance to it
        // is below threshold defined in `InstructionCardHighlightDistance` - highlight it.
        if isCurrentCardStep,
           distance < InstructionCardHighlightDistance {
            state = .highighted
        } else {
            state = .unhighlighted
        }
        
        instructionsCardView.updateDistanceFromCurrentLocation(distance)
    }
    
    private func commonInit() {
        translatesAutoresizingMaskIntoConstraints = false
        
        setupInformationStackView()
        instructionsCardView.primaryLabel.instructionDelegate = self
        instructionsCardView.secondaryLabel.instructionDelegate = self
    }
    
    private func setupInformationStackView() {
        addSubview(informationStackView)
        
        let informationStackViewTopConstraint = informationStackView.topAnchor.constraint(equalTo: topAnchor)
        let informationStackViewBottomConstraint = informationStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        let informationStackViewLeadingConstraint = informationStackView.leadingAnchor.constraint(equalTo: leadingAnchor)
        let informationStackViewTrailingConstraint = informationStackView.trailingAnchor.constraint(equalTo: trailingAnchor)
        
        let informationStackViewConstraints = [
            informationStackViewTopConstraint,
            informationStackViewBottomConstraint,
            informationStackViewLeadingConstraint,
            informationStackViewTrailingConstraint
        ]
        
        NSLayoutConstraint.activate(informationStackViewConstraints)
        
        let informationStackViewSubviews = [
            instructionsCardView,
            lanesView,
            nextBannerView
        ]
        informationStackView.addArrangedSubviews(informationStackViewSubviews)
    }
    
    private func updateInstructionsCardContainerView(for state: InstructionsCardContainerView.State) {
        let borderColor: UIColor
        let backgroundColor: UIColor
        switch state {
        case .unhighlighted:
            borderColor = separatorColor
            backgroundColor = customBackgroundColor
        case .highighted:
            borderColor = highlightedSeparatorColor
            backgroundColor = highlightedBackgroundColor
        }
        
        layer.borderWidth = 1 / UIScreen.main.scale
        layer.borderColor = borderColor.cgColor
        self.backgroundColor = backgroundColor
    }
    
    private func updateInstructionsCardView(for state: InstructionsCardContainerView.State) {
        let backgroundColor: UIColor
        let shouldUseHighlightedColors: Bool
        let separatorColor: UIColor
        switch state {
        case .unhighlighted:
            shouldUseHighlightedColors = false
            backgroundColor = customBackgroundColor
            separatorColor = self.separatorColor
        case .highighted:
            shouldUseHighlightedColors = true
            backgroundColor = highlightedBackgroundColor
            separatorColor = highlightedSeparatorColor
        }
        
        instructionsCardView.backgroundColor = backgroundColor
        instructionsCardView.separatorView.backgroundColor = separatorColor
        instructionsCardView.primaryLabel.showHighlightedTextColor = shouldUseHighlightedColors
        instructionsCardView.secondaryLabel.showHighlightedTextColor = shouldUseHighlightedColors
        instructionsCardView.distanceLabel.showHighlightedTextColor = shouldUseHighlightedColors
        instructionsCardView.maneuverView.shouldShowHighlightedColors = shouldUseHighlightedColors
    }
    
    private func updateLanesView(for state: InstructionsCardContainerView.State) {
        let backgroundColor: UIColor
        let shouldUseHighlightedColors: Bool
        switch state {
        case .unhighlighted:
            shouldUseHighlightedColors = false
            backgroundColor = customBackgroundColor
        case .highighted:
            shouldUseHighlightedColors = true
            backgroundColor = highlightedBackgroundColor
        }
        
        lanesView.backgroundColor = backgroundColor
        
        guard let stackView = lanesView.subviews.first as? UIStackView else {
            return
        }
        let laneViews = stackView.subviews.compactMap { $0 as? LaneView }
        laneViews.forEach { laneView in
            laneView.showHighlightedColors = shouldUseHighlightedColors
        }
    }
    
    private func updateNextBannerView(for state: InstructionsCardContainerView.State) {
        let backgroundColor: UIColor
        let shouldUseHighlightedColors: Bool
        switch state {
        case .unhighlighted:
            shouldUseHighlightedColors = false
            backgroundColor = customBackgroundColor
        case .highighted:
            shouldUseHighlightedColors = true
            backgroundColor = highlightedBackgroundColor
        }
        
        nextBannerView.backgroundColor = backgroundColor
        nextBannerView.maneuverView.shouldShowHighlightedColors = shouldUseHighlightedColors
        nextBannerView.instructionLabel.showHighlightedTextColor = shouldUseHighlightedColors
    }
    
    // MARK: InstructionsCardContainerViewDelegate Methods
    
    public func label(_ label: InstructionLabel,
                      willPresent instruction: VisualInstruction,
                      as presented: NSAttributedString) -> NSAttributedString? {
        if let primaryLabel = label as? PrimaryLabel,
           let presented = delegate?.primaryLabel(primaryLabel,
                                                  willPresent: instruction,
                                                  as: presented) {
            return presented
        } else if let secondaryLabel = label as? SecondaryLabel,
                  let presented = delegate?.secondaryLabel(secondaryLabel,
                                                           willPresent: instruction,
                                                           as: presented) {
            return presented
        } else {
            let highlighted = instructionsCardView.distanceFromCurrentLocation < InstructionCardHighlightDistance
            let textColor = highlighted ? instructionsCardView.primaryLabel.textColor : instructionsCardView.primaryLabel.textColorHighlighted
            let attributes = [
                NSAttributedString.Key.foregroundColor: textColor as Any
            ]
            
            let range = NSRange(location: 0, length: presented.length)
            let mutable = NSMutableAttributedString(attributedString: presented)
            mutable.addAttributes(attributes, range: range)
            
            return mutable
        }
    }
}
