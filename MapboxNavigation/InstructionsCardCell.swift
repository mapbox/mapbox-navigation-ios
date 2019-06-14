import UIKit
import MapboxDirections
import MapboxCoreNavigation

class InstructionsCardCell: UICollectionViewCell {
    
    var container: InstructionsCardContainerView!
    var style: InstructionsCardStyle = DayInstructionsCardStyle() {
        didSet {
            container.prepareLayout(for: style)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
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
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        /* TODO: Smoothen animation here. */
    }
    
    func configure(for step: RouteStep, distance: CLLocationDistance, previewEnabled: Bool) {
        container.updateInstruction(for: step, distance: distance, previewEnabled: previewEnabled)
        addSubview(container)
        setupConstraints()
    }
}

