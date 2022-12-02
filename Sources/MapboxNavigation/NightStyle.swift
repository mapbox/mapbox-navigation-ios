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
    }
    
    override func applyPhoneOrPadStyling(for traitCollection: UITraitCollection) {
        super.applyPhoneOrPadStyling(for: traitCollection)
        
        SpeedLimitView.appearance(for: traitCollection).signBackColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
        
        FloatingButton.appearance(for: traitCollection).backgroundColor = .defaultDarkAppearanceBackgroundColor
        FloatingButton.appearance(for: traitCollection).tintColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        FloatingButton.appearance(for: traitCollection).borderColor = #colorLiteral(red: 0.3764705882, green: 0.4901960784, blue: 0.6117647059, alpha: 0.796599912)
        
        InstructionsCardContainerView.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardCell.self]).customBackgroundColor = .defaultDarkAppearanceBackgroundColor
        InstructionsCardContainerView.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardCell.self]).separatorColor = #colorLiteral(red: 0.3764705882, green: 0.4901960784, blue: 0.6117647059, alpha: 0.796599912)
        InstructionsCardContainerView.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardCell.self]).highlightedSeparatorColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        // On iOS, for Night style, regardless of currently used `UIUserInterfaceStyle`, `ExitView` and
        // `GenericRouteShield` use white color as a default one.
        ExitView.appearance(for: traitCollection).foregroundColor = .white
        ExitView.appearance(for: traitCollection).borderColor = .white
        ExitView.appearance(for: traitCollection).highlightColor = .black
        
        GenericRouteShield.appearance(for: traitCollection).foregroundColor = .white
        GenericRouteShield.appearance(for: traitCollection).borderColor = .white
        GenericRouteShield.appearance(for: traitCollection).highlightColor = .black
        
        DistanceRemainingLabel.appearance(for: traitCollection).normalTextColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
        
        DistanceRemainingLabel.appearance(for: traitCollection,
                                          whenContainedInInstancesOf: [RoutePreviewViewController.self]).normalTextColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
        
        ArrivalTimeLabel.appearance(for: traitCollection).normalTextColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
        
        ArrivalTimeLabel.appearance(for: traitCollection,
                                       whenContainedInInstancesOf: [RoutePreviewViewController.self]).normalTextColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
        
        DestinationLabel.appearance(for: traitCollection).normalTextColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
        
        Button.appearance(for: traitCollection).textColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        CancelButton.appearance(for: traitCollection).tintColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        
        PreviewButton.appearance(for: traitCollection).tintColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        StartButton.appearance(for: traitCollection).tintColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        
        DismissButton.appearance(for: traitCollection).backgroundColor = .defaultDarkAppearanceBackgroundColor
        DismissButton.appearance(for: traitCollection).textColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        
        LaneView.appearance(for: traitCollection).primaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        LaneView.appearance(for: traitCollection).secondaryColor = #colorLiteral(red: 0.4198532104, green: 0.4398920536, blue: 0.4437610507, alpha: 1)
        
        LanesView.appearance(for: traitCollection).backgroundColor = .defaultDarkAppearanceBackgroundColor
        
        StepsBackgroundView.appearance(for: traitCollection).backgroundColor = .defaultDarkAppearanceBackgroundColor
        StepsTableHeaderView.appearance(for: traitCollection).tintColor = #colorLiteral(red: 0.103291966, green: 0.1482483149, blue: 0.2006777823, alpha: 1)
        StepsTableHeaderView.appearance(for: traitCollection).normalTextColor = #colorLiteral(red: 0.9996390939, green: 1, blue: 0.9997561574, alpha: 1)
        
        StepInstructionsView.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 0.103291966, green: 0.1482483149, blue: 0.2006777823, alpha: 1)
        StepTableViewCell.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 0.103291966, green: 0.1482483149, blue: 0.2006777823, alpha: 1)
        UITableView.appearance(for: traitCollection, whenContainedInInstancesOf: [StepsViewController.self]).backgroundColor = #colorLiteral(red: 0.103291966, green: 0.1482483149, blue: 0.2006777823, alpha: 1)
        
        UILabel.appearance(for: traitCollection, whenContainedInInstancesOf: [FeedbackViewController.self]).backgroundColor = .black
        UILabel.appearance(for: traitCollection, whenContainedInInstancesOf: [FeedbackViewController.self]).textColor = .white
        
        FeedbackStyleView.appearance(for: traitCollection, whenContainedInInstancesOf: [FeedbackViewController.self]).backgroundColor = .black
        FeedbackCollectionView.appearance(for: traitCollection).backgroundColor = .black
        FeedbackCollectionView.appearance(for: traitCollection).cellColor = .white
        
        UILabel.appearance(for: traitCollection, whenContainedInInstancesOf: [FeedbackViewController.self]).backgroundColor = .black
        UILabel.appearance(for: traitCollection, whenContainedInInstancesOf: [FeedbackViewController.self]).textColor = .white
        FeedbackStyleView.appearance(for: traitCollection, whenContainedInInstancesOf: [FeedbackViewController.self]).backgroundColor = .black
        FeedbackCollectionView.appearance(for: traitCollection).backgroundColor = .black
        FeedbackCollectionView.appearance(for: traitCollection).cellColor = .white
        FeedbackSubtypeCollectionViewCell.appearance(for: traitCollection).normalCircleColor = .black
        FeedbackSubtypeCollectionViewCell.appearance(for: traitCollection).normalCircleOutlineColor = .lightText
        
        TopBannerView.appearance(for: traitCollection).backgroundColor = .defaultDarkAppearanceBackgroundColor
        BottomBannerView.appearance(for: traitCollection).backgroundColor = .defaultDarkAppearanceBackgroundColor
        BottomPaddingView.appearance(for: traitCollection).backgroundColor = .defaultDarkAppearanceBackgroundColor
        InstructionsBannerView.appearance(for: traitCollection).backgroundColor = .defaultDarkAppearanceBackgroundColor
        
        WayNameView.appearance(for: traitCollection).borderColor = #colorLiteral(red: 0.2802129388, green: 0.3988235593, blue: 0.5260632038, alpha: 1)
        WayNameLabel.appearance(for: traitCollection).roadShieldBlackColor = #colorLiteral(red: 0.08, green: 0.09, blue: 0.12, alpha: 1)
        WayNameLabel.appearance(for: traitCollection).roadShieldBlueColor = #colorLiteral(red: 0.18, green: 0.26, blue: 0.66, alpha: 1)
        WayNameLabel.appearance(for: traitCollection).roadShieldGreenColor = #colorLiteral(red: 0.07, green: 0.51, blue: 0.22, alpha: 1)
        WayNameLabel.appearance(for: traitCollection).roadShieldRedColor = #colorLiteral(red: 0.86, green: 0.06, blue: 0.06, alpha: 1)
        WayNameLabel.appearance(for: traitCollection).roadShieldWhiteColor = #colorLiteral(red: 0.78, green: 0.78, blue: 0.78, alpha: 1)
        WayNameLabel.appearance(for: traitCollection).roadShieldYellowColor = #colorLiteral(red: 1.0, green: 0.85, blue: 0.08, alpha: 1)
        WayNameLabel.appearance(for: traitCollection).roadShieldDefaultColor = #colorLiteral(red: 0.08, green: 0.09, blue: 0.12, alpha: 1)
        
        ManeuverView.appearance(for: traitCollection).backgroundColor = .clear
        ManeuverView.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self]).primaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        ManeuverView.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self]).secondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.3)
        ManeuverView.appearance(for: traitCollection, whenContainedInInstancesOf: [NextBannerView.self]).primaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        ManeuverView.appearance(for: traitCollection, whenContainedInInstancesOf: [NextBannerView.self]).secondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.3)
        ManeuverView.appearance(for: traitCollection, whenContainedInInstancesOf: [StepInstructionsView.self]).primaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        ManeuverView.appearance(for: traitCollection, whenContainedInInstancesOf: [StepInstructionsView.self]).secondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.3)
        ManeuverView.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).primaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        ManeuverView.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).secondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.3)
        
        DistanceLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self]).unitTextColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
        DistanceLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self]).valueTextColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        DistanceLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [StepInstructionsView.self]).unitTextColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
        DistanceLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [StepInstructionsView.self]).valueTextColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        DistanceLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).unitTextColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
        DistanceLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).valueTextColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        
        EndOfRouteButton.appearance(for: traitCollection).textColor = .white
        EndOfRouteCommentView.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 0.1875049942, green: 0.2981707989, blue: 0.4181857639, alpha: 1)
        EndOfRouteCommentView.appearance(for: traitCollection).normalTextColor = .white
        EndOfRouteContentView.appearance(for: traitCollection).backgroundColor = .defaultDarkAppearanceBackgroundColor
        EndOfRouteStaticLabel.appearance(for: traitCollection).alpha = 1.0
        EndOfRouteStaticLabel.appearance(for: traitCollection).textColor = UIColor.white.withAlphaComponent(0.9)
        EndOfRouteTitleLabel.appearance(for: traitCollection).textColor = .white
        
        TimeRemainingLabel.appearance(for: traitCollection).normalTextColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        TimeRemainingLabel.appearance(for: traitCollection).trafficUnknownColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        
        NavigationMapView.appearance(for: traitCollection).routeAlternateColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
        NavigationMapView.appearance(for: traitCollection).buildingDefaultColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        NavigationMapView.appearance(for: traitCollection).buildingHighlightColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
        
        NavigationView.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 0.0470588, green: 0.0509804, blue: 0.054902, alpha: 1)
        
        PrimaryLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self]).normalTextColor = #colorLiteral(red: 0.9996390939, green: 1, blue: 0.9997561574, alpha: 1)
        PrimaryLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [StepInstructionsView.self]).normalTextColor = #colorLiteral(red: 0.9996390939, green: 1, blue: 0.9997561574, alpha: 1)
        PrimaryLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).normalTextColor = #colorLiteral(red: 0.9996390939, green: 1, blue: 0.9997561574, alpha: 1)
        
        SecondaryLabel.appearance(for: traitCollection).normalFont = UIFont.systemFont(ofSize: 26.0, weight: .medium).adjustedFont
        SecondaryLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).normalTextColor = #colorLiteral(red: 0.7349056005, green: 0.7675836682, blue: 0.8063536286, alpha: 1)
        SecondaryLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self]).normalTextColor = #colorLiteral(red: 0.7349056005, green: 0.7675836682, blue: 0.8063536286, alpha: 1)
        SecondaryLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [StepInstructionsView.self]).normalTextColor = #colorLiteral(red: 0.7349056005, green: 0.7675836682, blue: 0.8063536286, alpha: 1)
        
        InstructionLabel.appearance(for: traitCollection).roadShieldBlackColor = #colorLiteral(red: 0.08, green: 0.09, blue: 0.12, alpha: 1)
        InstructionLabel.appearance(for: traitCollection).roadShieldBlueColor = #colorLiteral(red: 0.18, green: 0.26, blue: 0.66, alpha: 1)
        InstructionLabel.appearance(for: traitCollection).roadShieldGreenColor = #colorLiteral(red: 0.07, green: 0.51, blue: 0.22, alpha: 1)
        InstructionLabel.appearance(for: traitCollection).roadShieldRedColor = #colorLiteral(red: 0.86, green: 0.06, blue: 0.06, alpha: 1)
        InstructionLabel.appearance(for: traitCollection).roadShieldWhiteColor = #colorLiteral(red: 0.78, green: 0.78, blue: 0.78, alpha: 1)
        InstructionLabel.appearance(for: traitCollection).roadShieldYellowColor = #colorLiteral(red: 1.0, green: 0.85, blue: 0.08, alpha: 1)
        InstructionLabel.appearance(for: traitCollection).roadShieldDefaultColor = #colorLiteral(red: 0.08, green: 0.09, blue: 0.12, alpha: 1)
        
        SeparatorView.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 0.3764705882, green: 0.4901960784, blue: 0.6117647059, alpha: 0.796599912)
        SeparatorView.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        RatingControl.appearance(for: traitCollection).normalColor = #colorLiteral(red: 0.149668334, green: 0.1680230035, blue: 0.1472480238, alpha: 1)
        RatingControl.appearance(for: traitCollection).selectedColor = #colorLiteral(red: 0.9803059896, green: 0.9978019022, blue: 1, alpha: 1)
        
        ResumeButton.appearance(for: traitCollection).backgroundColor = .defaultDarkAppearanceBackgroundColor
        ResumeButton.appearance(for: traitCollection).tintColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        ResumeButton.appearance(for: traitCollection).borderColor = #colorLiteral(red: 0.3764705882, green: 0.4901960784, blue: 0.6117647059, alpha: 0.796599912)
        
        BackButton.appearance(for: traitCollection).backgroundColor = .defaultDarkAppearanceBackgroundColor
        BackButton.appearance(for: traitCollection).tintColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        BackButton.appearance(for: traitCollection).textColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        BackButton.appearance(for: traitCollection).borderColor = #colorLiteral(red: 0.3764705882, green: 0.4901960784, blue: 0.6117647059, alpha: 0.796599912)
        
        NextBannerView.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 0.103291966, green: 0.1482483149, blue: 0.2006777823, alpha: 1)
        
        NextInstructionLabel.appearance(for: traitCollection).normalTextColor = #colorLiteral(red: 0.984, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        NextInstructionLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [NextBannerView.self]).normalTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    }
    
    override func applyCarPlayStyling() {
        super.applyCarPlayStyling()
        
        let carPlayTraitCollection = UITraitCollection(userInterfaceIdiom: .carPlay)
        
        SpeedLimitView.appearance(for: carPlayTraitCollection).signBackColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
        
        // `CarPlayCompassView` appearance styling. `CarPlayCompassView` is only used on CarPlay
        // and is not shared across other platforms.
        CarPlayCompassView.appearance(for: carPlayTraitCollection).backgroundColor = .defaultDarkAppearanceBackgroundColor
        
        // `StylableLabel` is used in `CarPlayCompassView` to show compass direction.
        StylableLabel.appearance(for: carPlayTraitCollection, whenContainedInInstancesOf: [CarPlayCompassView.self]).normalTextColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        
        WayNameView.appearance(for: carPlayTraitCollection).borderColor = #colorLiteral(red: 0.2802129388, green: 0.3988235593, blue: 0.5260632038, alpha: 1)
        WayNameLabel.appearance(for: carPlayTraitCollection).roadShieldBlackColor = #colorLiteral(red: 0.08, green: 0.09, blue: 0.12, alpha: 1)
        WayNameLabel.appearance(for: carPlayTraitCollection).roadShieldBlueColor = #colorLiteral(red: 0.18, green: 0.26, blue: 0.66, alpha: 1)
        WayNameLabel.appearance(for: carPlayTraitCollection).roadShieldGreenColor = #colorLiteral(red: 0.07, green: 0.51, blue: 0.22, alpha: 1)
        WayNameLabel.appearance(for: carPlayTraitCollection).roadShieldRedColor = #colorLiteral(red: 0.86, green: 0.06, blue: 0.06, alpha: 1)
        WayNameLabel.appearance(for: carPlayTraitCollection).roadShieldWhiteColor = #colorLiteral(red: 0.78, green: 0.78, blue: 0.78, alpha: 1)
        WayNameLabel.appearance(for: carPlayTraitCollection).roadShieldYellowColor = #colorLiteral(red: 1.0, green: 0.85, blue: 0.08, alpha: 1)
        WayNameLabel.appearance(for: carPlayTraitCollection).roadShieldDefaultColor = #colorLiteral(red: 0.08, green: 0.09, blue: 0.12, alpha: 1)
        
        ManeuverView.appearance(for: carPlayTraitCollection).backgroundColor = .clear
        
        NavigationMapView.appearance(for: carPlayTraitCollection).routeAlternateColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
        NavigationMapView.appearance(for: carPlayTraitCollection).buildingDefaultColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        NavigationMapView.appearance(for: carPlayTraitCollection).buildingHighlightColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
        
        SecondaryLabel.appearance(for: carPlayTraitCollection).normalFont = UIFont.systemFont(ofSize: 26.0, weight: .medium).adjustedFont
        
        InstructionLabel.appearance(for: carPlayTraitCollection).roadShieldBlackColor = #colorLiteral(red: 0.08, green: 0.09, blue: 0.12, alpha: 1)
        InstructionLabel.appearance(for: carPlayTraitCollection).roadShieldBlueColor = #colorLiteral(red: 0.18, green: 0.26, blue: 0.66, alpha: 1)
        InstructionLabel.appearance(for: carPlayTraitCollection).roadShieldGreenColor = #colorLiteral(red: 0.07, green: 0.51, blue: 0.22, alpha: 1)
        InstructionLabel.appearance(for: carPlayTraitCollection).roadShieldRedColor = #colorLiteral(red: 0.86, green: 0.06, blue: 0.06, alpha: 1)
        InstructionLabel.appearance(for: carPlayTraitCollection).roadShieldWhiteColor = #colorLiteral(red: 0.78, green: 0.78, blue: 0.78, alpha: 1)
        InstructionLabel.appearance(for: carPlayTraitCollection).roadShieldYellowColor = #colorLiteral(red: 1.0, green: 0.85, blue: 0.08, alpha: 1)
        InstructionLabel.appearance(for: carPlayTraitCollection).roadShieldDefaultColor = #colorLiteral(red: 0.08, green: 0.09, blue: 0.12, alpha: 1)
    }
}
