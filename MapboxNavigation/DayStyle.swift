import Foundation
import Mapbox

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
open class DayStyle: Style {
    
    public required init() {
        super.init()
        mapStyleURL = URL(string: "mapbox://styles/mapbox/navigation-guidance-day-v2")!
        styleType = .dayStyle
        statusBarStyle = .default
    }
    
    open override func apply() {
        super.apply()
        
        // General styling
        if let color = UIApplication.shared.delegate?.window??.tintColor {
            tintColor = color
        } else {
            tintColor = .defaultTint
        }
        
        Button.appearance().textColor = .defaultPrimaryText
        
        LineView.appearance().lineColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1)
        SeparatorView.appearance().backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.1)
        
        WayNameLabel.appearance().font = UIFont.systemFont(ofSize:20, weight: UIFontWeightMedium).adjustedFont
        WayNameLabel.appearance().textColor = #colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)
        WayNameView.appearance().borderColor = UIColor.defaultRouteCasing.withAlphaComponent(0.8)
        WayNameView.appearance().backgroundColor = UIColor.defaultRouteLayer.withAlphaComponent(0.85)
        
        TurnArrowView.appearance().primaryColor = .defaultTurnArrowPrimary
        TurnArrowView.appearance().secondaryColor = .defaultTurnArrowSecondary
        CellTurnArrowView.appearance().primaryColor = .defaultTurnArrowPrimary
        CellTurnArrowView.appearance().secondaryColor = .defaultTurnArrowSecondary
        
        LanesView.appearance().backgroundColor = #colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)
        LaneArrowView.appearance().primaryColor = .defaultLaneArrowPrimary
        LaneArrowView.appearance().secondaryColor = .defaultLaneArrowSecondary
        
        FloatingButton.appearance().tintColor = tintColor
        FloatingButton.appearance().backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        // Maneuver view (Page view)
        ManeuverView.appearance().backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        DistanceLabel.appearance().font = UIFont.systemFont(ofSize: 26).adjustedFont
        DistanceLabel.appearance().textColor = #colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1)
        
        DestinationLabel.appearance().font = UIFont.systemFont(ofSize: 32, weight: UIFontWeightMedium).adjustedFont
        DestinationLabel.appearance().textColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
        
        ArrivalTimeLabel.appearance().font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightMedium).adjustedFont
        ArrivalTimeLabel.appearance().textColor = .defaultPrimaryText
        
        // Table view (Drawer)
        RouteTableViewHeaderView.appearance().backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        TimeRemainingLabel.appearance().font = UIFont.systemFont(ofSize: 28, weight: UIFontWeightMedium).adjustedFont
        TimeRemainingLabel.appearance().textColor = .defaultPrimaryText
        TimeRemainingLabel.appearance().trafficUnknownColor = .defaultPrimaryText
        TimeRemainingLabel.appearance().trafficLowColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        TimeRemainingLabel.appearance().trafficModerateColor = #colorLiteral(red:0.95, green:0.65, blue:0.31, alpha:1.0)
        TimeRemainingLabel.appearance().trafficHeavyColor = #colorLiteral(red:0.91, green:0.20, blue:0.25, alpha:1.0)
        TimeRemainingLabel.appearance().trafficSevereColor = #colorLiteral(red:0.54, green:0.06, blue:0.22, alpha:1.0)
        
        DistanceRemainingLabel.appearance().textColor = #colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1)
        DistanceRemainingLabel.appearance().font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightMedium).adjustedFont
        
        ArrivalTimeLabel.appearance().textColor = .defaultPrimaryText
        ArrivalTimeLabel.appearance().font = UIFont.systemFont(ofSize: 18, weight: UIFontWeightMedium).adjustedFont
        
        CellTitleLabel.appearance().font = UIFont.systemFont(ofSize: 17).adjustedFont
        CellTitleLabel.appearance().textColor = .defaultPrimaryText
        
        CellSubtitleLabel.appearance().font = UIFont.systemFont(ofSize: 17).adjustedFont
        CellSubtitleLabel.appearance().textColor = .defaultSecondaryText
        
        NavigationMapView.appearance().routeCasingColor         = .defaultRouteCasing
        NavigationMapView.appearance().trafficUnknownColor      = .trafficUnknown
        NavigationMapView.appearance().trafficLowColor          = .trafficLow
        NavigationMapView.appearance().trafficModerateColor     = .trafficModerate
        NavigationMapView.appearance().trafficHeavyColor        = .trafficHeavy
        NavigationMapView.appearance().trafficSevereColor       = .trafficSevere
        
        ResumeButton.appearance().backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        ResumeButton.appearance().tintColor = .defaultPrimaryText
        
        CancelButton.appearance().tintColor = .defaultPrimaryText
        
        UIApplication.shared.statusBarStyle = statusBarStyle ?? .default
    }
}

/**
 `NightStyle` is default night style for Mapbox Navigation SDK. Only will be applied when necessary and if `automaticallyAdjustStyleForSunPosition`.
 */
open class NightStyle: DayStyle {
    
    public required init() {
        super.init()
        mapStyleURL = URL(string: "mapbox://styles/mapbox/navigation-guidance-night-v2")!
        styleType = .nightStyle
        statusBarStyle = .lightContent
    }
    
    open override func apply() {
        super.apply()
        
        let backgroundColor = #colorLiteral(red: 0.1493228376, green: 0.2374534607, blue: 0.333029449, alpha: 1)
        
        Button.appearance().textColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        ManeuverView.appearance().backgroundColor = backgroundColor
        
        DistanceLabel.appearance().textColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
        DestinationLabel.appearance().textColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        TimeRemainingLabel.appearance().textColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        TimeRemainingLabel.appearance().trafficUnknownColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        DistanceRemainingLabel.appearance().textColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
        ArrivalTimeLabel.appearance().textColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
        
        CellTurnArrowView.appearance().primaryColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        CellTurnArrowView.appearance().secondaryColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
        
        RouteTableViewHeaderView.appearance().backgroundColor = backgroundColor
        
        FloatingButton.appearance().backgroundColor = backgroundColor
        FloatingButton.appearance().tintColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        
        WayNameLabel.appearance().textColor = #colorLiteral(red: 0.9213390946, green: 0.9254172444, blue: 0.9335884452, alpha: 1)
        WayNameLabel.appearance().backgroundColor = .clear
        WayNameView.appearance().borderColor = #colorLiteral(red: 0.2802129388, green: 0.3988235593, blue: 0.5260632038, alpha: 1)
        
        TurnArrowView.appearance().primaryColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
        TurnArrowView.appearance().secondaryColor = #colorLiteral(red: 0.8, green: 0.8235294118, blue: 0.8481693864, alpha: 0.5)
        
        LanesView.appearance().backgroundColor = backgroundColor
        LaneArrowView.appearance().primaryColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        
        ResumeButton.appearance().backgroundColor = backgroundColor
        ResumeButton.appearance().tintColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        
        CancelButton.appearance().tintColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
    }
}
