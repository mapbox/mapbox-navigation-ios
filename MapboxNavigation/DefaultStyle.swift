import Foundation


extension UIColor {
    class var defaultRouteCasing: UIColor { get { return .defaultTintStroke } }
    class var defaultRouteLayer: UIColor { get { return #colorLiteral(red:0.00, green:0.70, blue:0.99, alpha:1.0) } }
    class var defaultArrowStroke: UIColor { get { return .defaultTint } }
    
    class var defaultTurnArrowPrimary: UIColor { get { return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) } }
    class var defaultTurnArrowSecondary: UIColor { get { return #colorLiteral(red: 0.6196078431, green: 0.6196078431, blue: 0.6196078431, alpha: 1) } }
    
    class var defaultLaneArrowPrimary: UIColor { get { return #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1) } }
    class var defaultLaneArrowSecondary: UIColor { get { return #colorLiteral(red: 0.6196078431, green: 0.6196078431, blue: 0.6196078431, alpha: 1) } }
    
    class var trafficUnknown: UIColor { get { return defaultRouteLayer } }
    class var trafficLow: UIColor { get { return defaultRouteLayer } }
    class var trafficModerate: UIColor { get { return #colorLiteral(red:0.95, green:0.65, blue:0.31, alpha:1.0) } }
    class var trafficHeavy: UIColor { get { return #colorLiteral(red:0.91, green:0.20, blue:0.25, alpha:1.0) } }
    class var trafficSevere: UIColor { get { return #colorLiteral(red:0.54, green:0.06, blue:0.22, alpha:1.0) } }
    class var trafficAlternateLow: UIColor { get { return #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1) } }
}

extension UIColor {
    // General styling
    fileprivate class var defaultTint: UIColor { get { return #colorLiteral(red: 0.1411764771, green: 0.3960784376, blue: 0.5647059083, alpha: 1) } }
    fileprivate class var defaultTintStroke: UIColor { get { return #colorLiteral(red:0.18, green:0.49, blue:0.78, alpha:1.0) } }
    fileprivate class var defaultPrimaryText: UIColor { get { return #colorLiteral(red: 45.0/255.0, green: 45.0/255.0, blue: 45.0/255.0, alpha: 1) } }
    fileprivate class var defaultSecondaryText: UIColor { get { return #colorLiteral(red: 0.4509803922, green: 0.4509803922, blue: 0.4509803922, alpha: 1) } }
}

extension UIFont {
    // General styling
    fileprivate class var defaultPrimaryText: UIFont { get { return UIFont.systemFont(ofSize: 26) } }
    fileprivate class var defaultSecondaryText: UIFont { get { return UIFont.systemFont(ofSize: 16) } }
    fileprivate class var defaultCellTitleLabel: UIFont { get { return UIFont.systemFont(ofSize: 28, weight: UIFontWeightMedium) } }
}


/**
 `DefaultStyle` is default style for Mapbox Navigation SDK.
 */
open class DefaultStyle: Style {
    
    required public init(traitCollection: UITraitCollection) {
        super.init(traitCollection: traitCollection)
        
        // General styling
        if let color = UIApplication.shared.delegate?.window??.tintColor {
            tintColor = color
        } else {
            tintColor = .defaultTint
        }
        
        statusBarStyle = .default
        
        buttonTextColor = .defaultPrimaryText
        lineColor =  #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1)
        
        wayNameLabelFont = .systemFont(ofSize: 16)
        wayNameLabelTextColor = #colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)
        wayNameViewBorderColor = UIColor.defaultRouteCasing.withAlphaComponent(0.8)
        wayNameViewBackgroundColor = UIColor.defaultRouteLayer.withAlphaComponent(0.85)
        
        turnArrowPrimaryColor = .defaultTurnArrowPrimary
        turnArrowSecondaryColor = .defaultTurnArrowSecondary
        
        laneViewPrimaryColor = .defaultLaneArrowPrimary
        laneViewSecondaryColor = .defaultLaneArrowSecondary
        
        floatingButtonBackgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        lanesViewBackgroundColor = #colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)
        
        // Maneuver view (Page view)
        maneuverViewBackgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        distanceLabelFont = .systemFont(ofSize: 26)
        distanceLabelTextColor = #colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1)
        
        destinationLabelFont = .systemFont(ofSize: 32, weight: UIFontWeightMedium)
        destinationLabelTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
        
        arrivalTimeLabelFont = .systemFont(ofSize: 18, weight: UIFontWeightMedium)
        arrivalTimeLabelTextColor = .defaultPrimaryText
        
        // Table view (Drawer)
        headerBackgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        timeRemainingLabelTextColor = .defaultPrimaryText
        timeRemainingLabelFont = .systemFont(ofSize: 28, weight: UIFontWeightMedium)
        
        distanceRemainingLabelTextColor = #colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1)
        distanceRemainingLabelFont = .systemFont(ofSize: 18, weight: UIFontWeightMedium)
        
        arrivalTimeLabelTextColor = .defaultPrimaryText
        arrivalTimeLabelFont = .systemFont(ofSize: 18, weight: UIFontWeightMedium)
        
        cellTitleLabelFont = .systemFont(ofSize: 17)
        cellTitleLabelTextColor = .defaultPrimaryText
        
        cellSubtitleLabelFont = .systemFont(ofSize: 17)
        cellSubtitleLabelTextColor = .defaultSecondaryText
        
        trafficUnknownColor = .trafficUnknown
        trafficLowColor = .trafficLow
        trafficModerateColor = .trafficModerate
        trafficHeavyColor = .trafficHeavy
        trafficSevereColor = .trafficSevere
        lowTrafficTextColor = .trafficAlternateLow
        
        routeCasingColor = .defaultRouteCasing
    }
    
}
