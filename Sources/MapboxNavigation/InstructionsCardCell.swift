import CoreLocation
import UIKit
import MapboxDirections

/// :nodoc:
public class InstructionsCardCell: UICollectionViewCell {
    public let container: InstructionsCardContainerView = .init()
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    private func commonInit() {
        configureLayer()
        addSubview(container)
        setupConstraints()
    }
    
    private func configureLayer() {
        backgroundColor = .clear
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 1, height: 2)
        layer.shadowRadius = 1
        layer.shadowOpacity = 0.4
    }
    
    private func setupConstraints() {
        container.translatesAutoresizingMaskIntoConstraints = false
        container.topAnchor.constraint(equalTo: topAnchor, constant: 2).isActive = true
        container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
    }
    public func configure(for step: RouteStep, distance: CLLocationDistance, instruction: VisualInstructionBanner? = nil, isCurrentCardStep: Bool = false) {
        container.updateInstruction(for: step,
                                    distance: distance,
                                    instruction: instruction,
                                    isCurrentCardStep: isCurrentCardStep)
    }
}

