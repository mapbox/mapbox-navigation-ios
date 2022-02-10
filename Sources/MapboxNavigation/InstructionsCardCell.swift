import CoreLocation
import UIKit
import MapboxDirections

/// :nodoc:
public class InstructionsCardCell: UICollectionViewCell {
    
    public let container: InstructionsCardContainerView = .init()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        configureLayer()
        addSubview(container)
        setupConstraints()
    }
    
    private func configureLayer() {
        backgroundColor = .clear
    }
    
    private func setupConstraints() {
        container.translatesAutoresizingMaskIntoConstraints = false
        container.topAnchor.constraint(equalTo: topAnchor).isActive = true
        container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
    }
    
    public func configure(for step: RouteStep,
                          distance: CLLocationDistance,
                          instruction: VisualInstructionBanner? = nil,
                          isCurrentCardStep: Bool = false) {
        container.updateInstruction(for: step,
                                       distance: distance,
                                       instruction: instruction,
                                       isCurrentCardStep: isCurrentCardStep)
    }
}
