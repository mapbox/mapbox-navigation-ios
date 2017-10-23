import UIKit

@IBDesignable
@objc(MBInstructionsBannerView)
class InstructionsBannerView: UIView {
    
    weak var gravityView: UIView!
    weak var turnArrowView: TurnArrowView!
    weak var primaryLabel: UILabel!
    weak var secondaryLabel: UILabel!
    weak var distanceLabel: DistanceLabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        turnArrowView.isStart = true
    }
    
    func commonInit() {
        let gravityView = UIView()
        gravityView.translatesAutoresizingMaskIntoConstraints = false
        gravityView.backgroundColor = .red
        addSubview(gravityView)
        self.gravityView = gravityView
        
        let turnArrowView = TurnArrowView()
        turnArrowView.backgroundColor = .blue
        turnArrowView.translatesAutoresizingMaskIntoConstraints = false
        gravityView.addSubview(turnArrowView)
        self.turnArrowView = turnArrowView
        
        let distanceLabel = DistanceLabel()
        distanceLabel.text = "10052m"
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.minimumScaleFactor = 0.2
        gravityView.addSubview(distanceLabel)
        self.distanceLabel = distanceLabel
        
        let primaryLabel = UILabel()
        primaryLabel.translatesAutoresizingMaskIntoConstraints = false
        primaryLabel.text = "Primary Label"
        addSubview(primaryLabel)
        self.primaryLabel = primaryLabel
        
        let secondaryLabel = UILabel()
        secondaryLabel.translatesAutoresizingMaskIntoConstraints = false
        secondaryLabel.text = "Secondary Label"
        addSubview(secondaryLabel)
        self.secondaryLabel = secondaryLabel
        
        let views = ["gravityView": gravityView, "turnArrowView": turnArrowView, "distanceLabel": distanceLabel, "primaryLabel": primaryLabel, "secondaryLabel": secondaryLabel]
        
        // Gravity view (the view that centers the turn arrow and distance label on the Y axis)
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[gravityView(50)]", options: [], metrics: nil, views: views))
        // Wrap bottom of the distance label to the bottom of the gravity view
        addConstraint(NSLayoutConstraint(item: gravityView, attribute: .bottom, relatedBy: .equal, toItem: distanceLabel, attribute: .bottom, multiplier: 1, constant: 0))
        
        addConstraint(NSLayoutConstraint(item: gravityView, attribute: .centerY, relatedBy: .equal, toItem: self, attribute: .centerY, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: gravityView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1, constant: 8))

        // Turn arrow view
        addConstraint(NSLayoutConstraint(item: turnArrowView, attribute: .top, relatedBy: .equal, toItem: gravityView, attribute: .top, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: turnArrowView, attribute: .leading, relatedBy: .equal, toItem: gravityView, attribute: .leading, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: turnArrowView, attribute: .trailing, relatedBy: .equal, toItem: gravityView, attribute: .trailing, multiplier: 1, constant: 0))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[turnArrowView(50)]", options: [], metrics: nil, views: views))
        
        // Distance label
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[turnArrowView][distanceLabel]", options: [], metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-(>=0)-[distanceLabel]-(>=0)-|", options: [], metrics: nil, views: views))
        
        // Constrain distance label top to the bottom of the turn arrow
        addConstraint(NSLayoutConstraint(item: distanceLabel, attribute: .top, relatedBy: .equal, toItem: turnArrowView, attribute: .bottom, multiplier: 1, constant: 0))
        
        // Constrain distance label to the bottom of the turn arrow
        //addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[turnArrowView]-0-[distanceLabel]", options: [], metrics: nil, views: views))
        
        // Constrain secondary label bottom baseline to the baseline of the distance label
        addConstraint(NSLayoutConstraint(item: secondaryLabel, attribute: .lastBaseline, relatedBy: .equal, toItem: distanceLabel, attribute: .lastBaseline, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: secondaryLabel, attribute: .leading, relatedBy: .equal, toItem: gravityView, attribute: .trailing, multiplier: 1, constant: 8))
        
        // Constrain primary label bottom to the top of the secondary label
        addConstraint(NSLayoutConstraint(item: primaryLabel, attribute: .bottom, relatedBy: .equal, toItem: secondaryLabel, attribute: .top, multiplier: 1, constant: 0))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "[turnArrowView]-8-[primaryLabel]", options: [], metrics: nil, views: views))
    }
}
