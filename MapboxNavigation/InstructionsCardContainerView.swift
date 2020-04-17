import UIKit
import MapboxDirections
import MapboxCoreNavigation

/**
 :nodoc:
 The `InstructionsCardContainerViewDelegate` protocol defines a method that allows an object to customize presented visual instructions within the instructions container view.
 */
public protocol InstructionsCardContainerViewDelegate: VisualInstructionDelegate {
    /**
     Called when the Primary Label will present a visual instruction.
     
     - parameter primaryLabel: The custom primary label that the instruction will be presented on.
     - parameter instruction: the `VisualInstruction` that will be presented.
     - parameter presented: the formatted string that is provided by the instruction presenter
     - returns: optionally, a customized NSAttributedString that will be presented instead of the default, or if nil, the default behavior will be used.
     */
    func primaryLabel(_ primaryLabel: InstructionLabel, willPresent instruction: VisualInstruction, as presented: NSAttributedString) -> NSAttributedString?
    
    /**
     Called when the Secondary Label will present a visual instruction.
     
     - parameter secondaryLabel: The custom secondary label that the instruction will be presented on.
     - parameter instruction: the `VisualInstruction` that will be presented.
     - parameter presented: the formatted string that is provided by the instruction presenter
     - returns: optionally, a customized NSAttributedString that will be presented instead of the default, or if nil, the default behavior will be used.
     */
    func secondaryLabel(_ secondaryLabel: InstructionLabel, willPresent instruction: VisualInstruction, as presented: NSAttributedString) -> NSAttributedString?
}

public extension InstructionsCardContainerViewDelegate {
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func primaryLabel(_ primaryLabel: InstructionLabel, willPresent instruction: VisualInstruction, as presented: NSAttributedString) -> NSAttributedString? {
        logUnimplemented(protocolType: InstructionsCardContainerViewDelegate.self, level: .debug)
        return nil
    }
    
    /**
     `UnimplementedLogging` prints a warning to standard output the first time this method is called.
     */
    func secondaryLabel(_ secondaryLabel: InstructionLabel, willPresent instruction: VisualInstruction, as presented: NSAttributedString) -> NSAttributedString? {
        logUnimplemented(protocolType: InstructionsCardContainerViewDelegate.self,level: .debug)
        return nil
    }
}

/// :nodoc:
public class InstructionsCardContainerView: UIView {
    lazy var informationStackView = UIStackView(orientation: .vertical, autoLayout: true)
    
    lazy var instructionsCardView: InstructionsCardView = {
        let cardView: InstructionsCardView = InstructionsCardView()
        cardView.translatesAutoresizingMaskIntoConstraints = false
        return cardView
    }()
    
    lazy var lanesView: LanesView = .forAutoLayout(hidden: true)
    lazy var nextBannerView: NextBannerView = .forAutoLayout(hidden: true)
    
    private var informationChildren: [UIView] {
        return [instructionsCardView] + secondaryChildren
    }
    
    private var secondaryChildren: [UIView] {
        return [lanesView, nextBannerView]
    }
    
    public weak var delegate: InstructionsCardContainerViewDelegate?
    
    private var gradientLayer: CAGradientLayer!
    private (set) var style: InstructionsCardStyle!
    
    required public init(style: InstructionsCardStyle? = DayInstructionsCardStyle()) {
        super.init(frame: .zero)
        self.style = style
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    public func prepareLayout(for style: InstructionsCardStyle) {
        self.style = style
        self.instructionsCardView.style = style
        commonInit()
    }
    
    public func updateBackgroundColor(highlightEnabled: Bool) {
        prepareLayout()
        guard highlightEnabled else { return }
        highlightContainerView()
    }
    
    func commonInit() {
        addStackConstraints()
        setupInformationStackView()
        prepareLayout()
        
        instructionsCardView.primaryLabel.instructionDelegate = self
        instructionsCardView.secondaryLabel.instructionDelegate = self
    }
    
    private func addStackConstraints() {
        addSubview(informationStackView)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        let top = informationStackView.topAnchor.constraint(equalTo: self.topAnchor)
        let leading = informationStackView.leadingAnchor.constraint(equalTo: self.leadingAnchor)
        let trailing = informationStackView.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        let bottom = bottomAnchor.constraint(equalTo: informationStackView.bottomAnchor)
        
        NSLayoutConstraint.activate([top, leading, trailing, bottom])
    }
    
    private func setupInformationStackView() {
        informationStackView.insertArrangedSubview(instructionsCardView, at: 0)
        informationStackView.addArrangedSubviews(secondaryChildren)
    }
    
    private func prepareLayout() {
        setGradientLayer(for: self)
        setGradientLayer(for: instructionsCardView)
        setGradientLayer(for: lanesView)
        setGradientLayer(for: nextBannerView)
        
        layer.cornerRadius = style.cornerRadius
        layer.masksToBounds = true
        
        instructionsCardView.prepareLayout()
    }
    
    @discardableResult private func setGradientLayer(for view: UIView) -> UIView {
        guard !view.isHidden else { return view }
        
        let backgroundColor = style.backgroundColor
        let alphaComponent = InstructionsCardConstants.backgroundColorAlphaComponent
        let colors = [backgroundColor.cgColor, backgroundColor.withAlphaComponent(alphaComponent).cgColor]

        let requiresGradient = (gradientLayer(for: view) == nil)
        
        if requiresGradient {
            let gradientLayer = CAGradientLayer()
            view.layer.insertSublayer(gradientLayer, at: 0)
        }
        
        if let gradientLayer = view.layer.sublayers?.first as? CAGradientLayer {
            gradientLayer.frame = bounds
            gradientLayer.colors = colors
        }
        
        if let nextBannerView = view as? NextBannerView {
            nextBannerView.maneuverView.primaryColor = style.nextBannerViewPrimaryColor
            nextBannerView.maneuverView.secondaryColor = style.nextBannerViewSecondaryColor
            nextBannerView.instructionLabel.normalTextColor = style.nextBannerInstructionLabelTextColor
            nextBannerView.instructionLabel.normalFont = style.nextBannerInstructionLabelNormalFont
            nextBannerView.instructionLabel.shieldHeight = style.nextBannerInstructionLabelNormalFont.pointSize
        }
        
        if let lanesView = view as? LanesView, let stackView = lanesView.subviews.first as? UIStackView {
            let laneViews: [LaneView] = stackView.subviews.compactMap { $0 as? LaneView }
            laneViews.forEach { laneView in
                guard laneView.isValid else { return }
                laneView.primaryColor = self.style.lanesViewDefaultColor
                laneView.secondaryColor = self.style.lanesViewDefaultColor
            }
        }
        
        view.layoutIfNeeded()
        
        return view
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
    }
    
    private func gradientLayer(for view: UIView, with colors:[CGColor]? = nil) -> CAGradientLayer? {
        guard !view.isHidden, let sublayers = view.layer.sublayers,
            let firstLayer = sublayers.first as? CAGradientLayer,
            let layerColors = firstLayer.colors as? [CGColor], layerColors.count == 2 else {
            return nil
        }
        
        if let colors = colors {
            let colorsMatched = layerColors.reduce(false) { $0 || colors.contains($1) }
            return colorsMatched ? firstLayer : nil
        }
        
        return firstLayer
    }
    
    public func updateInstruction(for step: RouteStep, distance: CLLocationDistance) {
        instructionsCardView.updateDistanceFromCurrentLocation(distance)
        instructionsCardView.step = step
        
        guard let instruction = step.instructionsDisplayedAlongStep?.last else { return }
        updateInstruction(instruction)
        updateInstructionCard(distance: distance)
    }
    
    public func updateInstruction(_ instruction: VisualInstructionBanner) {
        lanesView.update(for: instruction)
        nextBannerView.instructionDelegate = self
        nextBannerView.update(for: instruction)
    }
    
    public func updateInstructionCard(distance: CLLocationDistance) {
        let highlightEnabled = distance < InstructionsCardConstants.highlightDistance
        updateBackgroundColor(highlightEnabled: highlightEnabled)
        instructionsCardView.updateDistanceFromCurrentLocation(distance)
    }
    
    func highlightContainerView() {
        let duration = InstructionsCardConstants.highlightAnimationDuration
        let alphaComponent = InstructionsCardConstants.highlightedBackgroundAlphaComponent
        
        let colors = [style.highlightedBackgroundColor.cgColor,
                      style.highlightedBackgroundColor.withAlphaComponent(alphaComponent).cgColor]

        let containerGradientLayer = gradientLayer(for: self)
        var instructionsCardViewGradientLayer = gradientLayer(for: instructionsCardView)
        var lanesViewGradientLayer = gradientLayer(for: lanesView)
        var nextBannerGradientLayer = gradientLayer(for: nextBannerView)
        
        if lanesView.isCurrentlyVisible && lanesViewGradientLayer == nil {
            let view = setGradientLayer(for: lanesView)
            lanesViewGradientLayer = view.layer.sublayers?.first as? CAGradientLayer
        }
        
        if nextBannerView.isCurrentlyVisible && nextBannerGradientLayer == nil {
            let view = setGradientLayer(for: nextBannerView)
            nextBannerGradientLayer = view.layer.sublayers?.first as? CAGradientLayer
        }
        
        if instructionsCardViewGradientLayer == nil {
            let view = setGradientLayer(for: instructionsCardView)
            instructionsCardViewGradientLayer = view.layer.sublayers?.first as? CAGradientLayer
        }
        
        UIView.animate(withDuration: duration, animations: {
            if let lanesViewGradientLayer = lanesViewGradientLayer {
                self.highlightLanesView(lanesViewGradientLayer, colors: colors)
            }
            
            if let nextBannerGradientLayer = nextBannerGradientLayer {
                self.hightlightNextBannerView(nextBannerGradientLayer, colors: colors)
            }
            
            if let containerGradientLayer = containerGradientLayer {
                containerGradientLayer.colors = colors
            }
            
            if let instructionsCardViewGradientLayer = instructionsCardViewGradientLayer {
                instructionsCardViewGradientLayer.colors = colors
            }
            
            self.highlightInstructionsCardView(colors: colors)
        })
    }
    
    fileprivate func highlightLanesView(_ gradientLayer: CAGradientLayer, colors: [CGColor]) {
        gradientLayer.colors = colors
        guard let stackView = lanesView.subviews.first as? UIStackView else {
            return
        }
        let laneViews: [LaneView] = stackView.subviews.compactMap { $0 as? LaneView }
        laneViews.forEach { laneView in
            guard laneView.isValid else { return }
            laneView.primaryColor = style.lanesViewHighlightedColor
            laneView.secondaryColor = style.lanesViewHighlightedColor
        }
    }
    
    fileprivate func hightlightNextBannerView(_ gradientLayer: CAGradientLayer, colors: [CGColor]) {
        gradientLayer.colors = colors
        nextBannerView.maneuverView.primaryColor = style.nextBannerInstructionHighlightedColor
        nextBannerView.maneuverView.secondaryColor = style.nextBannerInstructionSecondaryHighlightedColor
        nextBannerView.instructionLabel.normalTextColor = style.nextBannerInstructionHighlightedColor
    }
    
    fileprivate func highlightInstructionsCardView(colors: [CGColor]) {
        // primary & secondary labels
        instructionsCardView.primaryLabel.normalTextColor = style.primaryLabelHighlightedTextColor
        instructionsCardView.secondaryLabel.normalTextColor = style.secondaryLabelHighlightedTextColor
        // distance label
        instructionsCardView.distanceLabel.unitTextColor = style.distanceLabelHighlightedTextColor
        instructionsCardView.distanceLabel.valueTextColor = style.distanceLabelHighlightedTextColor
        // maneuver view
        instructionsCardView.maneuverView.primaryColor = style.maneuverViewHighlightedColor
        instructionsCardView.maneuverView.secondaryColor = style.maneuverViewSecondaryHighlightedColor
    }
}

/// :nodoc:
extension InstructionsCardContainerView: InstructionsCardContainerViewDelegate {
    public func label(_ label: InstructionLabel, willPresent instruction: VisualInstruction, as presented: NSAttributedString) -> NSAttributedString? {
        if let primaryLabel = label as? PrimaryLabel,
            let presented = delegate?.primaryLabel(primaryLabel, willPresent: instruction, as: presented) {
            return presented
        } else if let secondaryLabel = label as? SecondaryLabel,
            let presented = delegate?.secondaryLabel(secondaryLabel, willPresent: instruction, as: presented) {
            return presented
        } else {
            let highlighted = instructionsCardView.distanceFromCurrentLocation < InstructionsCardConstants.highlightDistance
            let textColor = highlighted ? style.primaryLabelTextColor : style.primaryLabelHighlightedTextColor
            let attributes = [NSAttributedString.Key.foregroundColor: textColor]
            
            let range = NSRange(location: 0, length: presented.length)
            let mutable = NSMutableAttributedString(attributedString: presented)
            mutable.addAttributes(attributes, range: range)
            
            return mutable
        }
    }
}
