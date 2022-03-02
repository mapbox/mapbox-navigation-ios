import UIKit
import MapboxMaps

/**
 `NightStyle` is the default night style for Mapbox Navigation SDK. Only will be applied when necessary and if `automaticallyAdjustStyleForSunPosition`.
 */
open class NightStyle: DayStyle {
    public required init() {
        super.init()
        
        mapStyleURL = URL(string: StyleURI.navigationNight.rawValue)!
        previewMapStyleURL = mapStyleURL
        styleType = .night
        statusBarStyle = .lightContent
    }
    
    open override func apply() {
        super.apply()
        
        let backgroundColor = #colorLiteral(red: 0.1493228376, green: 0.2374534607, blue: 0.333029449, alpha: 1)
        
        ArrivalTimeLabel.appearance().normalTextColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
        BottomBannerView.appearance().backgroundColor = backgroundColor
        Button.appearance().textColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        CancelButton.appearance().tintColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        
        CarPlayCompassView.appearance().backgroundColor = backgroundColor
        
        DismissButton.appearance().backgroundColor = backgroundColor
        DismissButton.appearance().textColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        DistanceLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).unitTextColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
        DistanceLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).valueTextColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        DistanceLabel.appearance(whenContainedInInstancesOf: [StepInstructionsView.self]).unitTextColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
        DistanceLabel.appearance(whenContainedInInstancesOf: [StepInstructionsView.self]).valueTextColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        DistanceLabel.appearance(whenContainedInInstancesOf: [InstructionsCardView.self]).unitTextColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
        DistanceLabel.appearance(whenContainedInInstancesOf: [InstructionsCardView.self]).valueTextColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)


        DistanceRemainingLabel.appearance().normalTextColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
        EndOfRouteButton.appearance().textColor = .white
        EndOfRouteCommentView.appearance().backgroundColor = #colorLiteral(red: 0.1875049942, green: 0.2981707989, blue: 0.4181857639, alpha: 1)
        EndOfRouteCommentView.appearance().normalTextColor = .white
        EndOfRouteContentView.appearance().backgroundColor = backgroundColor
        EndOfRouteStaticLabel.appearance().alpha = 1.0
        EndOfRouteStaticLabel.appearance().textColor = UIColor.white.withAlphaComponent(0.9)
        EndOfRouteTitleLabel.appearance().textColor = .white
        
        // On iOS, for Night style, regardless of currently used `UIUserInterfaceStyle`, `ExitView` and
        // `GenericRouteShield` use white color as a default one.
        ExitView.appearance().foregroundColor = .white
        ExitView.appearance().borderColor = .white
        
        GenericRouteShield.appearance().foregroundColor = .white
        GenericRouteShield.appearance().borderColor = .white
        
        FloatingButton.appearance().backgroundColor = backgroundColor
        FloatingButton.appearance().tintColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        InstructionsBannerView.appearance().backgroundColor = backgroundColor
        InstructionsCardContainerView.appearance(whenContainedInInstancesOf: [InstructionsCardCell.self]).customBackgroundColor = backgroundColor
        InstructionsCardContainerView.appearance(whenContainedInInstancesOf: [InstructionsCardCell.self]).separatorColor = #colorLiteral(red: 0.3764705882, green: 0.4901960784, blue: 0.6117647059, alpha: 0.796599912)
        InstructionsCardContainerView.appearance(whenContainedInInstancesOf: [InstructionsCardCell.self]).highlightedSeparatorColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        LaneView.appearance().primaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        LaneView.appearance().secondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.3)
        LaneView.appearance(whenContainedInInstancesOf: [LanesView.self]).primaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        LaneView.appearance(whenContainedInInstancesOf: [LanesView.self]).secondaryColor = #colorLiteral(red: 0.4198532104, green: 0.4398920536, blue: 0.4437610507, alpha: 1)
        LanesView.appearance().backgroundColor = backgroundColor
        ManeuverView.appearance().backgroundColor = .clear
        ManeuverView.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).primaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        ManeuverView.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).secondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.3)
        ManeuverView.appearance(whenContainedInInstancesOf: [NextBannerView.self]).primaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        ManeuverView.appearance(whenContainedInInstancesOf: [NextBannerView.self]).secondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.3)
        ManeuverView.appearance(whenContainedInInstancesOf: [StepInstructionsView.self]).primaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        ManeuverView.appearance(whenContainedInInstancesOf: [StepInstructionsView.self]).secondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.3)
        ManeuverView.appearance(whenContainedInInstancesOf: [InstructionsCardView.self]).primaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        ManeuverView.appearance(whenContainedInInstancesOf: [InstructionsCardView.self]).secondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.3)

        NavigationMapView.appearance().routeAlternateColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
        NavigationMapView.appearance().buildingDefaultColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        NavigationMapView.appearance().buildingHighlightColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
        NavigationView.appearance().backgroundColor = #colorLiteral(red: 0.0470588, green: 0.0509804, blue: 0.054902, alpha: 1)
        NextBannerView.appearance().backgroundColor = #colorLiteral(red: 0.103291966, green: 0.1482483149, blue: 0.2006777823, alpha: 1)
        NextInstructionLabel.appearance().normalTextColor = #colorLiteral(red: 0.984, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        NextInstructionLabel.appearance(whenContainedInInstancesOf: [NextBannerView.self]).normalTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)

        PrimaryLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).normalTextColor = #colorLiteral(red: 0.9996390939, green: 1, blue: 0.9997561574, alpha: 1)
        PrimaryLabel.appearance(whenContainedInInstancesOf: [StepInstructionsView.self]).normalTextColor = #colorLiteral(red: 0.9996390939, green: 1, blue: 0.9997561574, alpha: 1)
        PrimaryLabel.appearance(whenContainedInInstancesOf: [InstructionsCardView.self]).normalTextColor = #colorLiteral(red: 0.9996390939, green: 1, blue: 0.9997561574, alpha: 1)

        ProgressBar.appearance().barColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        RatingControl.appearance().normalColor = #colorLiteral(red: 0.149668334, green: 0.1680230035, blue: 0.1472480238, alpha: 1)
        RatingControl.appearance().selectedColor = #colorLiteral(red: 0.9803059896, green: 0.9978019022, blue: 1, alpha: 1)
        ReportButton.appearance().backgroundColor = backgroundColor
        ReportButton.appearance().textColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        ResumeButton.appearance().backgroundColor = backgroundColor
        ResumeButton.appearance().tintColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        SecondaryLabel.appearance().normalFont = UIFont.systemFont(ofSize: 26, weight: .medium).adjustedFont
        SecondaryLabel.appearance(whenContainedInInstancesOf: [InstructionsCardView.self]).normalTextColor = #colorLiteral(red: 0.7349056005, green: 0.7675836682, blue: 0.8063536286, alpha: 1)
        SecondaryLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).normalTextColor = #colorLiteral(red: 0.7349056005, green: 0.7675836682, blue: 0.8063536286, alpha: 1)
        SecondaryLabel.appearance(whenContainedInInstancesOf: [StepInstructionsView.self]).normalTextColor = #colorLiteral(red: 0.7349056005, green: 0.7675836682, blue: 0.8063536286, alpha: 1)
        SeparatorView.appearance().backgroundColor = #colorLiteral(red: 0.3764705882, green: 0.4901960784, blue: 0.6117647059, alpha: 0.796599912)
        SeparatorView.appearance(whenContainedInInstancesOf: [InstructionsCardView.self]).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        SpeedLimitView.appearance().signBackColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
        StepInstructionsView.appearance().backgroundColor = #colorLiteral(red: 0.103291966, green: 0.1482483149, blue: 0.2006777823, alpha: 1)
        StepTableViewCell.appearance().backgroundColor = #colorLiteral(red: 0.103291966, green: 0.1482483149, blue: 0.2006777823, alpha: 1)
        UITableView.appearance(whenContainedInInstancesOf: [StepsViewController.self]).backgroundColor = #colorLiteral(red: 0.103291966, green: 0.1482483149, blue: 0.2006777823, alpha: 1)
        StepsBackgroundView.appearance().backgroundColor = backgroundColor
        StylableLabel.appearance(whenContainedInInstancesOf: [CarPlayCompassView.self]).normalTextColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        TimeRemainingLabel.appearance().normalTextColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        TimeRemainingLabel.appearance().trafficUnknownColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        TopBannerView.appearance().backgroundColor = backgroundColor
        WayNameView.appearance().borderColor = #colorLiteral(red: 0.2802129388, green: 0.3988235593, blue: 0.5260632038, alpha: 1)
        StepsTableHeaderView.appearance().tintColor = #colorLiteral(red: 0.103291966, green: 0.1482483149, blue: 0.2006777823, alpha: 1)
        StepsTableHeaderView.appearance().normalTextColor = #colorLiteral(red: 0.9996390939, green: 1, blue: 0.9997561574, alpha: 1)
    }
}
