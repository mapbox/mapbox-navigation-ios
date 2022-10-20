import UIKit
import MapboxNavigation

class CustomDayStyle: DayStyle {
    
    class var defaultTintColor: UIColor { #colorLiteral(red: 0.237, green: 0.242, blue: 0.242, alpha: 1) }
    
    required init() {
        super.init()
    }

    override func apply() {
        super.apply()
        
        tintColor = CustomDayStyle.defaultTintColor
        
        let phoneTraitCollection = UITraitCollection(userInterfaceIdiom: .phone)
        
        let regularAndRegularSizeClassTraitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(verticalSizeClass: .regular),
            UITraitCollection(horizontalSizeClass: .regular)
        ])
        
        let regularAndCompactSizeClassTraitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(verticalSizeClass: .regular),
            UITraitCollection(horizontalSizeClass: .compact)
        ])
        
        let compactAndRegularSizeClassTraitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(verticalSizeClass: .compact),
            UITraitCollection(horizontalSizeClass: .regular)
        ])
        
        let compactAndCompactSizeClassTraitCollection = UITraitCollection(traitsFrom: [
            UITraitCollection(verticalSizeClass: .compact),
            UITraitCollection(horizontalSizeClass: .compact)
        ])
        
        BottomBannerView.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        BottomPaddingView.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        
        WayNameView.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        WayNameView.appearance(for: phoneTraitCollection).borderColor = #colorLiteral(red: 0.804, green: 0.816, blue: 0.816, alpha: 1)
        WayNameView.appearance(for: phoneTraitCollection).borderWidth = 2.0
        
        WayNameLabel.appearance(for: phoneTraitCollection).textAlignment = .center
        WayNameLabel.appearance(for: phoneTraitCollection).normalFont = UIFont.systemFont(ofSize: 18.0, weight: .regular).adjustedFont
        WayNameLabel.appearance(for: phoneTraitCollection).normalTextColor = #colorLiteral(red: 0.237, green: 0.242, blue: 0.242, alpha: 1)
        
        UserPuckCourseView.appearance(for: phoneTraitCollection).puckColor = #colorLiteral(red: 0.216, green: 0.212, blue: 0.454, alpha: 1)
        
//        CameraModeFloatingButton.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
//        CameraModeFloatingButton.appearance(for: phoneTraitCollection).tintColor = tintColor
//        CameraModeFloatingButton.appearance(for: phoneTraitCollection).borderWidth = Style.defaultBorderWidth
//        CameraModeFloatingButton.appearance(for: phoneTraitCollection).borderColor = .defaultBorderColor
        
        TimeRemainingLabel.appearance(for: regularAndRegularSizeClassTraitCollection).normalFont = UIFont.systemFont(ofSize: 27.0, weight: .medium).adjustedFont
        TimeRemainingLabel.appearance(for: regularAndCompactSizeClassTraitCollection).normalFont = UIFont.systemFont(ofSize: 27.0, weight: .medium).adjustedFont
        TimeRemainingLabel.appearance(for: compactAndRegularSizeClassTraitCollection).normalFont = UIFont.systemFont(ofSize: 27.0, weight: .medium).adjustedFont
        TimeRemainingLabel.appearance(for: compactAndCompactSizeClassTraitCollection).normalFont = UIFont.systemFont(ofSize: 27.0, weight: .medium).adjustedFont
        TimeRemainingLabel.appearance(for: phoneTraitCollection).normalTextColor = #colorLiteral(red: 0.216, green: 0.212, blue: 0.454, alpha: 1)
        
        DestinationLabel.appearance(for: phoneTraitCollection).normalTextColor = #colorLiteral(red: 0.216, green: 0.212, blue: 0.454, alpha: 1)
        DestinationLabel.appearance(for: phoneTraitCollection).normalFont = UIFont.systemFont(ofSize: 27.0)
        DestinationLabel.appearance(for: phoneTraitCollection).numberOfLines = 2
        
        DistanceRemainingLabel.appearance(for: phoneTraitCollection).normalFont = UIFont.systemFont(ofSize: 15.0)
        DistanceRemainingLabel.appearance(for: phoneTraitCollection).normalTextColor = #colorLiteral(red: 0.237, green: 0.242, blue: 0.242, alpha: 1)
        
        ArrivalTimeLabel.appearance(for: phoneTraitCollection).normalFont = UIFont.systemFont(ofSize: 15.0)
        ArrivalTimeLabel.appearance(for: phoneTraitCollection).normalTextColor = #colorLiteral(red: 0.237, green: 0.242, blue: 0.242, alpha: 1)
        
        ResumeButton.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
//        ResumeButton.appearance(for: phoneTraitCollection).tintColor = .defaultPrimaryTextColor
        ResumeButton.appearance(for: phoneTraitCollection).borderColor = #colorLiteral(red: 0.737254902, green: 0.7960784314, blue: 0.8705882353, alpha: 1)
//        ResumeButton.appearance(for: phoneTraitCollection).borderWidth = Style.defaultBorderWidth
        ResumeButton.appearance(for: phoneTraitCollection).cornerRadius = 5.0
        
        PreviewButton.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        PreviewButton.appearance(for: phoneTraitCollection).borderColor = #colorLiteral(red: 0.804, green: 0.816, blue: 0.816, alpha: 1)
        PreviewButton.appearance(for: phoneTraitCollection).borderWidth = 2.0
        PreviewButton.appearance(for: phoneTraitCollection).cornerRadius = 5.0
        PreviewButton.appearance(for: phoneTraitCollection).tintColor = #colorLiteral(red: 0.237, green: 0.242, blue: 0.242, alpha: 1)
        
        StartButton.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 0.216, green: 0.212, blue: 0.454, alpha: 1)
        StartButton.appearance(for: phoneTraitCollection).cornerRadius = 5.0
        StartButton.appearance(for: phoneTraitCollection).tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1)
    }
}
