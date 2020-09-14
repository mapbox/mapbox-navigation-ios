import UIKit
import MapboxDirections
import MapboxCoreNavigation

/**
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

/**
 A container view for the information currently displayed in `InstructionsCardViewController`.
 */
public class InstructionsCardContainerView: StylableView {
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

    @objc dynamic public var customBackgroundColor: UIColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    @objc dynamic public var highlightedBackgroundColor: UIColor = UIColor(red: 0.26, green: 0.39, blue: 0.98, alpha: 1.0)
    
    public weak var delegate: InstructionsCardContainerViewDelegate?
    
    private var gradientLayer: CAGradientLayer!
    
    required public init() {
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    public func prepareLayout() {
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
        setGradientLayer(for: self)
        setGradientLayer(for: instructionsCardView)
        setGradientLayer(for: lanesView)
        setGradientLayer(for: nextBannerView)
        
        instructionsCardView.prepareLayout()
        
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
    
    @discardableResult private func setGradientLayer(for view: UIView) -> UIView {
        guard !view.isHidden else { return view }

        let alphaComponent = InstructionsCardConstants.backgroundColorAlphaComponent
        let colors = [customBackgroundColor.cgColor, customBackgroundColor.withAlphaComponent(alphaComponent).cgColor]

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
            nextBannerView.maneuverView.shouldShowHighlightedColors = false
            nextBannerView.instructionLabel.showHighlightedTextColor = false
            nextBannerView.instructionLabel.shieldHeight = nextBannerView.instructionLabel.font.pointSize
        }
        
        if let lanesView = view as? LanesView, let stackView = lanesView.subviews.first as? UIStackView {
            let laneViews: [LaneView] = stackView.subviews.compactMap { $0 as? LaneView }
            laneViews.forEach { laneView in
                guard laneView.isValid else { return }
                laneView.showHighlightedColors = false
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
        
        let colors = [highlightedBackgroundColor.cgColor,
                      highlightedBackgroundColor.withAlphaComponent(alphaComponent).cgColor]

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
            laneView.showHighlightedColors = true
        }
    }
    
    fileprivate func hightlightNextBannerView(_ gradientLayer: CAGradientLayer, colors: [CGColor]) {
        gradientLayer.colors = colors
        nextBannerView.maneuverView.shouldShowHighlightedColors = true
        nextBannerView.instructionLabel.showHighlightedTextColor = true
    }
    
    fileprivate func highlightInstructionsCardView(colors: [CGColor]) {
        // primary & secondary labels
        instructionsCardView.primaryLabel.showHighlightedTextColor = true
        instructionsCardView.secondaryLabel.showHighlightedTextColor = true

        // distance label
        instructionsCardView.distanceLabel.showHighlightedTextColor = true

        // maneuver view
        instructionsCardView.maneuverView.shouldShowHighlightedColors = true
    }
}

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
            let textColor = highlighted ? instructionsCardView.primaryLabel.textColor : instructionsCardView.primaryLabel.textColorHighlighted
            let attributes = [NSAttributedString.Key.foregroundColor: textColor as Any]
            
            let range = NSRange(location: 0, length: presented.length)
            let mutable = NSMutableAttributedString(attributedString: presented)
            mutable.addAttributes(attributes, range: range)
            
            return mutable
        }
    }
}
