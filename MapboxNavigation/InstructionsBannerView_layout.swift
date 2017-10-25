import UIKit

extension InstructionsBannerView {
    
    func commonInit() {
        backgroundColor = .clear
        
        let turnArrowView = TurnArrowView()
        turnArrowView.backgroundColor = .clear
        turnArrowView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(turnArrowView)
        self.turnArrowView = turnArrowView
        
        let distanceLabel = DistanceLabel()
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.adjustsFontSizeToFitWidth = true
        distanceLabel.minimumScaleFactor = 0.2
        addSubview(distanceLabel)
        self.distanceLabel = distanceLabel
        
        let primaryLabel = PrimaryLabel()
        primaryLabel.translatesAutoresizingMaskIntoConstraints = false
        primaryLabel.adjustsFontSizeToFitWidth = true
        primaryLabel.numberOfLines = 1
        primaryLabel.minimumScaleFactor = 0.5
        primaryLabel.lineBreakMode = .byTruncatingTail
        addSubview(primaryLabel)
        self.primaryLabel = primaryLabel
        
        let secondaryLabel = SecondaryLabel()
        secondaryLabel.translatesAutoresizingMaskIntoConstraints = false
        secondaryLabel.adjustsFontSizeToFitWidth = true
        secondaryLabel.numberOfLines = 3
        secondaryLabel.minimumScaleFactor = 0.2
        secondaryLabel.lineBreakMode = .byTruncatingTail
        addSubview(secondaryLabel)
        self.secondaryLabel = secondaryLabel
        
        let views = ["turnArrowView": turnArrowView, "distanceLabel": distanceLabel, "primaryLabel": primaryLabel, "secondaryLabel": secondaryLabel]
        
        // Distance label
        addConstraint(NSLayoutConstraint(item: distanceLabel, attribute: .top, relatedBy: .equal, toItem: turnArrowView, attribute: .bottom, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: self, attribute: .bottom, relatedBy: .equal, toItem: distanceLabel, attribute: .bottom, multiplier: 1, constant: 8))
        addConstraint(NSLayoutConstraint(item: distanceLabel, attribute: .centerX, relatedBy: .equal, toItem: turnArrowView, attribute: .centerX, multiplier: 1, constant: 0))
        
        // Turn arrow view
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-8-[turnArrowView(50)]", options: [], metrics: nil, views: views))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[turnArrowView(50)][distanceLabel]", options: [], metrics: nil, views: views))
        
        // Secondary Label
        addConstraint(NSLayoutConstraint(item: distanceLabel, attribute: .lastBaseline, relatedBy: .equal, toItem: secondaryLabel, attribute: .lastBaseline, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: secondaryLabel, attribute: .leading, relatedBy: .equal, toItem: turnArrowView, attribute: .trailing, multiplier: 1, constant: 8))
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:[secondaryLabel]-(>=8)-|", options: [], metrics: nil, views: views))
        
        // Primary Label
        addConstraint(NSLayoutConstraint(item: primaryLabel, attribute: .top, relatedBy: .greaterThanOrEqual, toItem: self, attribute: .top, multiplier: 1, constant: 8))
        addConstraint(NSLayoutConstraint(item: primaryLabel, attribute: .bottom, relatedBy: .equal, toItem: secondaryLabel, attribute: .top, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: primaryLabel, attribute: .leading, relatedBy: .equal, toItem: secondaryLabel, attribute: .leading, multiplier: 1, constant: 0))
        addConstraint(NSLayoutConstraint(item: self, attribute: .right, relatedBy: .greaterThanOrEqual, toItem: primaryLabel, attribute: .right, multiplier: 1, constant: 8))
    }
}
