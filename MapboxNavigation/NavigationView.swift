import UIKit
import MapboxDirections

@IBDesignable
@objc(MBNavigationView)
public class NavigationView: UIView {
    
    weak var mapView: NavigationMapView!
    weak var wayNameLabel: WayNameLabel!
    weak var bottomBannerView: BottomBannerView!
    weak var bottomBannerContentView: BottomBannerContentView!
    weak var instructionsBannerView: InstructionsBannerView!
    weak var instructionsBannerContentView: InstructionsBannerContentView!
    weak var lanesView: LanesView!
    weak var nextBannerView: NextBannerView!
    weak var statusView: StatusView!
    weak var resumeButton: ResumeButton!
    // Vertically laid-out stack view below the instructions banner consisting of StatusView, NextBannerView, and LanesView.
    weak var informationStackView: UIStackView!
    
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
        setupConstraints()
    }
    
    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        mapView.prepareForInterfaceBuilder()
        
        instructionsBannerView.maneuverView.isStart = true
        instructionsBannerView.distance = 100
        
        lanesView.backgroundColor = #colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)
        lanesView.prepareForInterfaceBuilder()
        
        nextBannerView.backgroundColor = #colorLiteral(red: 0.9675388083, green: 0.9675388083, blue: 0.9675388083, alpha: 1)
        nextBannerView.instructionLabel.instruction = [VisualInstructionComponent(text: "Next step", imageURL: nil)]
        
        let primary = VisualInstructionComponent(text: "Primary text label", imageURL: nil)
        instructionsBannerView.set([primary], secondaryInstruction: nil)
        
        bottomBannerView.arrivalTimeLabel.text = bottomBannerView.dateFormatter.string(from: Date())
        bottomBannerContentView.backgroundColor = .white
        
        bottomBannerView.prepareForInterfaceBuilder()
        
        wayNameLabel.backgroundColor = .lightGray
        wayNameLabel.text = "Street Label"
    }
}


