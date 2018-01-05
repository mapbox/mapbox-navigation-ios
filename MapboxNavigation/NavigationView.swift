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
    }
    
    public override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        mapView.prepareForInterfaceBuilder()
        
        instructionsBannerView.maneuverView.isStart = true
        instructionsBannerView.distance = 100
        
        let primary = VisualInstructionComponent(text: "Primary text label", imageURL: nil)
        instructionsBannerView.set([primary], secondaryInstruction: nil)
        
        bottomBannerView.arrivalTimeLabel.text = bottomBannerView.dateFormatter.string(from: Date())
        bottomBannerContentView.backgroundColor = .white
        
        bottomBannerView.prepareForInterfaceBuilder()
        
        wayNameLabel.backgroundColor = .lightGray
        wayNameLabel.text = "Street Label"
    }
}


