import UIKit
import MapboxDirections

/**
 A view that represents the root view of the MapboxNavigation drop-in UI.
 
 ## Components
 
 1. InstructionsBannerView
 2. InformationStackView
 3. BottomBannerView
 4. ResumeButton
 5. WayNameLabel
 6. FloatingStackView
 7. NavigationMapView
 
 ```
 +--------------------+
 |         1          |
 +--------------------+
 |         2          |
 +----------------+---+
 |                |   |
 |                | 6 |
 |                |   |
 |         7      +---+
 |                    |
 |                    |
 |                    |
 +------------+       |
 |  4  ||  5  |       |
 +------------+-------+
 |         3          |
 +--------------------+
 ```
*/
@IBDesignable
@objc(MBNavigationView)
open class NavigationView: UIView {
    
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
    // Vertically laid-out stack view below the information stack view ontop of the map view, docked
    // to the top right, consisting of Overview, Mute, and Report button.
    weak var floatingStackView: UIStackView!
    weak var overviewButton: FloatingButton!
    weak var muteButton: FloatingButton!
    weak var reportButton: FloatingButton!
    weak var rerouteReportButton: ReportButton!
    weak var separatorView: SeparatorView!
    
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
    
    open override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        
        DayStyle().apply()
        
        mapView.prepareForInterfaceBuilder()
        instructionsBannerView.prepareForInterfaceBuilder()
        lanesView.prepareForInterfaceBuilder()
        bottomBannerView.prepareForInterfaceBuilder()
        nextBannerView.prepareForInterfaceBuilder()
        
        wayNameLabel.text = "Street Label"
    }
}
