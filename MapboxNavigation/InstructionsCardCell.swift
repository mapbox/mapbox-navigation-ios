import UIKit
import MapboxDirections
import MapboxCoreNavigation

/// :nodoc:
public class InstructionsCardCell: UICollectionViewCell {
    public var container: InstructionsCardContainerView!
    
    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    func commonInit() {
        container = InstructionsCardContainerView()
        configureLayer()
    }
    
    func configureLayer() {
        backgroundColor = .clear
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 1, height: 2)
        layer.shadowRadius = 1
        layer.shadowOpacity = 0.4
    }
    
    func setupConstraints() {
        container.translatesAutoresizingMaskIntoConstraints = false
        container.topAnchor.constraint(equalTo: topAnchor, constant: 2).isActive = true
        container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        /* TODO: Smoothen animation here. */
    }
    
    public func configure(for step: RouteStep, distance: CLLocationDistance) {
        addSubview(container)
        setupConstraints()
        container.prepareLayout()
        container.updateInstruction(for: step, distance: distance)
    }
}

