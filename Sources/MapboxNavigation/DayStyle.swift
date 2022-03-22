import UIKit
import MapboxMaps

/**
 `DefaultStyle` is default style for Mapbox Navigation SDK.
 */
open class DayStyle: Style {
    
    public required init() {
        super.init()
        
        mapStyleURL = URL(string: StyleURI.navigationDay.rawValue)!
        previewMapStyleURL = mapStyleURL
        styleType = .day
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
        
        ArrivalTimeLabel.appearance().normalFont = UIFont.systemFont(ofSize: 18, weight: .medium).adjustedFont
        ArrivalTimeLabel.appearance().normalTextColor = .defaultPrimaryText
        BottomBannerView.appearance().backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        Button.appearance().textColor = .defaultPrimaryText
        CancelButton.appearance().tintColor = .defaultPrimaryText
        
        CarPlayCompassView.appearance().backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.6022227113)
        CarPlayCompassView.appearance().cornerRadius = 4
        CarPlayCompassView.appearance().borderWidth = 1.0 / (UIScreen.mainCarPlay?.scale ?? 2.0)
        CarPlayCompassView.appearance().borderColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 0.6009573063)

        DismissButton.appearance().backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        DismissButton.appearance().textColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
        DismissButton.appearance().textFont = UIFont.systemFont(ofSize: 20, weight: .medium).adjustedFont
        DistanceLabel.appearance().unitFont = UIFont.systemFont(ofSize: 14, weight: .medium).adjustedFont
        DistanceLabel.appearance().valueFont = UIFont.systemFont(ofSize: 22, weight: .medium).adjustedFont
        DistanceLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).unitTextColor = #colorLiteral(red: 0.6274509804, green: 0.6274509804, blue: 0.6274509804, alpha: 1)
        DistanceLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).valueTextColor = #colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1)
        DistanceLabel.appearance(whenContainedInInstancesOf: [InstructionsCardView.self]).valueTextColor = #colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1)
        DistanceLabel.appearance(whenContainedInInstancesOf: [InstructionsCardView.self]).unitTextColor = #colorLiteral(red: 0.6274509804, green: 0.6274509804, blue: 0.6274509804, alpha: 1)
        DistanceLabel.appearance(whenContainedInInstancesOf: [InstructionsCardView.self]).unitFont = UIFont.systemFont(ofSize: 16.0).adjustedFont
        DistanceLabel.appearance(whenContainedInInstancesOf: [InstructionsCardView.self]).valueFont = UIFont.boldSystemFont(ofSize: 20.0).adjustedFont
        DistanceLabel.appearance(whenContainedInInstancesOf: [InstructionsCardView.self]).unitTextColorHighlighted = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        DistanceLabel.appearance(whenContainedInInstancesOf: [InstructionsCardView.self]).valueTextColorHighlighted = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        DistanceLabel.appearance(whenContainedInInstancesOf: [StepInstructionsView.self]).unitTextColor = #colorLiteral(red: 0.6274509804, green: 0.6274509804, blue: 0.6274509804, alpha: 1)
        DistanceLabel.appearance(whenContainedInInstancesOf: [StepInstructionsView.self]).valueTextColor = #colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1)
        DistanceRemainingLabel.appearance().normalFont = UIFont.systemFont(ofSize: 18, weight: .medium).adjustedFont
        DistanceRemainingLabel.appearance().normalTextColor = #colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1)
        EndOfRouteButton.appearance().textColor = .darkGray
        EndOfRouteButton.appearance().textFont = .systemFont(ofSize: 15)
        EndOfRouteContentView.appearance().backgroundColor = .white
        EndOfRouteStaticLabel.appearance().normalFont = .systemFont(ofSize: 14.0)
        EndOfRouteStaticLabel.appearance().normalTextColor = #colorLiteral(red: 0.217173934, green: 0.3645851612, blue: 0.489295125, alpha: 1)
        EndOfRouteTitleLabel.appearance().normalFont = .systemFont(ofSize: 36.0)
        EndOfRouteTitleLabel.appearance().normalTextColor = .black
        
        // On iOS, for Day style, regardless of currently used `UIUserInterfaceStyle`, `ExitView` and
        // `GenericRouteShield` use black color as a default one.
        ExitView.appearance().backgroundColor = .clear
        ExitView.appearance().borderWidth = 1.0
        ExitView.appearance().cornerRadius = 5.0
        ExitView.appearance().foregroundColor = .black
        ExitView.appearance().borderColor = .black
        
        GenericRouteShield.appearance().backgroundColor = .clear
        GenericRouteShield.appearance().borderWidth = 1.0
        GenericRouteShield.appearance().cornerRadius = 5.0
        GenericRouteShield.appearance().foregroundColor = .black
        GenericRouteShield.appearance().borderColor = .black
        
        // In case if CarPlay supports `UIUserInterfaceStyle` styling will be applied for a
        // `UITraitCollection`, which contains both `UIUserInterfaceIdiom` and `UIUserInterfaceStyle`.
        // If not, `UITraitCollection` will only contain `UIUserInterfaceIdiom`.
        if #available(iOS 12.0, *) {
            let carPlayTraitCollection = UITraitCollection(userInterfaceIdiom: .carPlay)
            
            let carPlayLightTraitCollection = UITraitCollection(traitsFrom: [
                carPlayTraitCollection,
                UITraitCollection(userInterfaceStyle: .light)
            ])
            setCarPlayInstructionsStyling(for: carPlayLightTraitCollection)
            
            let carPlayDarkTraitCollection = UITraitCollection(traitsFrom: [
                carPlayTraitCollection,
                UITraitCollection(userInterfaceStyle: .dark)
            ])
            setCarPlayInstructionsStyling(for: carPlayDarkTraitCollection)
        } else {
            setDefaultCarPlayInstructionsStyling()
        }
        
        FloatingButton.appearance().backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        FloatingButton.appearance().tintColor = tintColor
        InstructionsBannerView.appearance().backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        InstructionsCardContainerView.appearance(whenContainedInInstancesOf: [InstructionsCardCell.self]).customBackgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        InstructionsCardContainerView.appearance(whenContainedInInstancesOf: [InstructionsCardCell.self]).highlightedBackgroundColor = #colorLiteral(red: 0.26, green: 0.39, blue: 0.98, alpha: 1.0)
        InstructionsCardContainerView.appearance(whenContainedInInstancesOf: [InstructionsCardCell.self]).separatorColor = #colorLiteral(red: 0.737254902, green: 0.7960784314, blue: 0.8705882353, alpha: 1)
        InstructionsCardContainerView.appearance(whenContainedInInstancesOf: [InstructionsCardCell.self]).highlightedSeparatorColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        InstructionsCardContainerView.appearance(whenContainedInInstancesOf: [InstructionsCardCell.self]).clipsToBounds = true
        InstructionsCardContainerView.appearance(whenContainedInInstancesOf: [InstructionsCardCell.self]).cornerRadius = 20
        LaneView.appearance(for: UITraitCollection(userInterfaceIdiom: .carPlay)).primaryColor = .defaultLaneArrowPrimaryCarPlay
        LaneView.appearance(for: UITraitCollection(userInterfaceIdiom: .carPlay)).secondaryColor = .defaultLaneArrowSecondaryCarPlay
        LaneView.appearance(whenContainedInInstancesOf: [LanesView.self]).primaryColor = .defaultLaneArrowPrimary
        LaneView.appearance(whenContainedInInstancesOf: [LanesView.self]).secondaryColor = .defaultLaneArrowSecondary
        LaneView.appearance(whenContainedInInstancesOf: [LanesView.self]).primaryColorHighlighted = .defaultLaneArrowPrimaryHighlighted
        LaneView.appearance(whenContainedInInstancesOf: [LanesView.self]).secondaryColorHighlighted = .defaultLaneArrowSecondaryHighlighted
        LaneView.appearance().primaryColor = .defaultLaneArrowPrimaryCarPlay
        LaneView.appearance().secondaryColor = .defaultLaneArrowSecondaryCarPlay
        LaneView.appearance().primaryColorHighlighted = .defaultLaneArrowPrimaryHighlighted
        LaneView.appearance().secondaryColorHighlighted = .defaultLaneArrowSecondaryHighlighted
        LanesView.appearance().backgroundColor = #colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)
        ManeuverView.appearance().backgroundColor = .clear
        ManeuverView.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).primaryColor = .defaultTurnArrowPrimary
        ManeuverView.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).secondaryColor = .defaultTurnArrowSecondary
        ManeuverView.appearance(whenContainedInInstancesOf: [InstructionsCardView.self]).primaryColor = .defaultTurnArrowPrimary
        ManeuverView.appearance(whenContainedInInstancesOf: [InstructionsCardView.self]).secondaryColor = .defaultTurnArrowSecondary
        ManeuverView.appearance(whenContainedInInstancesOf: [NextBannerView.self]).primaryColor = .defaultTurnArrowPrimary
        ManeuverView.appearance(whenContainedInInstancesOf: [NextBannerView.self]).secondaryColor = .defaultTurnArrowSecondary
        ManeuverView.appearance(whenContainedInInstancesOf: [StepInstructionsView.self]).primaryColor = .defaultTurnArrowPrimary
        ManeuverView.appearance(whenContainedInInstancesOf: [StepInstructionsView.self]).secondaryColor = .defaultTurnArrowSecondary
        ManeuverView.appearance().primaryColorHighlighted = .defaultTurnArrowPrimaryHighlighted
        ManeuverView.appearance().secondaryColorHighlighted = .defaultTurnArrowSecondaryHighlighted
        NavigationMapView.appearance().maneuverArrowColor = .defaultManeuverArrow
        NavigationMapView.appearance().maneuverArrowStrokeColor = .defaultManeuverArrowStroke
        NavigationMapView.appearance().routeAlternateColor = .defaultAlternateLine
        NavigationMapView.appearance().routeCasingColor = .defaultRouteCasing
        NavigationMapView.appearance().traversedRouteColor = .defaultTraversedRouteColor
        NavigationMapView.appearance().trafficHeavyColor = .trafficHeavy
        NavigationMapView.appearance().trafficLowColor = .trafficLow
        NavigationMapView.appearance().trafficModerateColor = .trafficModerate
        NavigationMapView.appearance().trafficSevereColor = .trafficSevere
        NavigationMapView.appearance().trafficUnknownColor = .trafficUnknown
        NavigationMapView.appearance().alternativeTrafficHeavyColor = .alternativeTrafficHeavy
        NavigationMapView.appearance().alternativeTrafficLowColor = .alternativeTrafficLow
        NavigationMapView.appearance().alternativeTrafficModerateColor = .alternativeTrafficModerate
        NavigationMapView.appearance().alternativeTrafficSevereColor = .alternativeTrafficSevere
        NavigationMapView.appearance().alternativeTrafficUnknownColor = .alternativeTrafficUnknown
        NavigationMapView.appearance().buildingDefaultColor = .defaultBuildingColor
        NavigationMapView.appearance().buildingHighlightColor = .defaultBuildingHighlightColor
        NavigationMapView.appearance().routeDurationAnnotationColor = .routeDurationAnnotationColor
        NavigationMapView.appearance().routeDurationAnnotationSelectedColor = .selectedRouteDurationAnnotationColor
        NavigationMapView.appearance().routeDurationAnnotationFontNames = UIFont.defaultNavigationSymbolLayerFontNames
        NavigationMapView.appearance().routeDurationAnnotationTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
        NavigationMapView.appearance().routeDurationAnnotationSelectedTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        NavigationView.appearance().backgroundColor = #colorLiteral(red: 0.764706, green: 0.752941, blue: 0.733333, alpha: 1)
        NextBannerView.appearance().backgroundColor = #colorLiteral(red: 0.9675388083, green: 0.9675388083, blue: 0.9675388083, alpha: 1)
        NextBannerView.appearance(whenContainedInInstancesOf:[InstructionsCardContainerView.self]).backgroundColor = #colorLiteral(red: 0.9675388083, green: 0.9675388083, blue: 0.9675388083, alpha: 1)
        NextInstructionLabel.appearance().normalFont = UIFont.systemFont(ofSize: 20, weight: .medium).adjustedFont
        NextInstructionLabel.appearance().normalTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
        NextInstructionLabel.appearance(whenContainedInInstancesOf: [NextBannerView.self]).normalTextColor = UIColor(red: 0.15, green: 0.24, blue: 0.34, alpha: 1.0)
        NextInstructionLabel.appearance(whenContainedInInstancesOf: [NextBannerView.self]).textColorHighlighted = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        NextInstructionLabel.appearance(whenContainedInInstancesOf: [NextBannerView.self]).normalFont = UIFont.systemFont(ofSize: 14.0).adjustedFont
        PrimaryLabel.appearance().normalFont = UIFont.systemFont(ofSize: 30, weight: .medium).adjustedFont
        PrimaryLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).normalTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
        PrimaryLabel.appearance(whenContainedInInstancesOf: [InstructionsCardView.self]).normalTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
        PrimaryLabel.appearance(whenContainedInInstancesOf: [InstructionsCardView.self]).textColorHighlighted = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        PrimaryLabel.appearance(whenContainedInInstancesOf: [InstructionsCardView.self]).normalFont = UIFont.boldSystemFont(ofSize: 24.0).adjustedFont
        PrimaryLabel.appearance(whenContainedInInstancesOf: [StepInstructionsView.self]).normalTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
        RatingControl.appearance().normalColor = #colorLiteral(red: 0.8508961797, green: 0.8510394692, blue: 0.850877285, alpha: 1)
        RatingControl.appearance().selectedColor = #colorLiteral(red: 0.1205472574, green: 0.2422055006, blue: 0.3489340544, alpha: 1)
        ResumeButton.appearance().backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        ResumeButton.appearance().tintColor = .defaultPrimaryText
        SecondaryLabel.appearance().normalFont = UIFont.systemFont(ofSize: 26, weight: .medium).adjustedFont
        SecondaryLabel.appearance(whenContainedInInstancesOf: [InstructionsBannerView.self]).normalTextColor = #colorLiteral(red: 0.2156862745, green: 0.2156862745, blue: 0.2156862745, alpha: 1)
        SecondaryLabel.appearance(whenContainedInInstancesOf: [InstructionsCardView.self]).normalTextColor = #colorLiteral(red: 0.2156862745, green: 0.2156862745, blue: 0.2156862745, alpha: 1)
        SecondaryLabel.appearance(whenContainedInInstancesOf: [InstructionsCardView.self]).textColorHighlighted = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        SecondaryLabel.appearance(whenContainedInInstancesOf: [InstructionsCardView.self]).normalFont = UIFont.boldSystemFont(ofSize: 18.0).adjustedFont
        SecondaryLabel.appearance(whenContainedInInstancesOf: [StepInstructionsView.self]).normalTextColor = #colorLiteral(red: 0.2156862745, green: 0.2156862745, blue: 0.2156862745, alpha: 1)
        SeparatorView.appearance().backgroundColor = #colorLiteral(red: 0.737254902, green: 0.7960784314, blue: 0.8705882353, alpha: 1)
        SeparatorView.appearance(whenContainedInInstancesOf: [InstructionsCardView.self]).backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        SpeedLimitView.appearance().signBackColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        SpeedLimitView.appearance().textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        SpeedLimitView.appearance().regulatoryBorderColor = #colorLiteral(red: 0.800, green: 0, blue: 0, alpha: 1)
        StatusView.appearance().backgroundColor = UIColor.black.withAlphaComponent(2.0/3.0)
        StepInstructionsView.appearance().backgroundColor = #colorLiteral(red: 0.9675388083, green: 0.9675388083, blue: 0.9675388083, alpha: 1)
        StepListIndicatorView.appearance().gradientColors = [#colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1), #colorLiteral(red: 0.6274509804, green: 0.6274509804, blue: 0.6274509804, alpha: 1), #colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1)]
        StepTableViewCell.appearance().backgroundColor = #colorLiteral(red: 0.9675388083, green: 0.9675388083, blue: 0.9675388083, alpha: 1)
        UITableView.appearance(whenContainedInInstancesOf: [StepsViewController.self]).backgroundColor = #colorLiteral(red: 0.9675388083, green: 0.9675388083, blue: 0.9675388083, alpha: 1)
        StepsBackgroundView.appearance().backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        StylableLabel.appearance(whenContainedInInstancesOf: [CarPlayCompassView.self]).normalFont = UIFont.systemFont(ofSize: 12, weight: .medium).adjustedFont
        StylableLabel.appearance(whenContainedInInstancesOf: [CarPlayCompassView.self]).normalTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
        TimeRemainingLabel.appearance(for: regularAndRegularSizeClassTraitCollection).normalFont = UIFont.systemFont(ofSize: 28, weight: .medium).adjustedFont
        TimeRemainingLabel.appearance(for: regularAndCompactSizeClassTraitCollection).normalFont = UIFont.systemFont(ofSize: 28, weight: .medium).adjustedFont
        TimeRemainingLabel.appearance(for: compactAndRegularSizeClassTraitCollection).normalFont = UIFont.systemFont(ofSize: 28, weight: .medium).adjustedFont
        TimeRemainingLabel.appearance(for: compactAndCompactSizeClassTraitCollection).normalFont = UIFont.systemFont(ofSize: 18, weight: .medium).adjustedFont
        TimeRemainingLabel.appearance().normalFont = UIFont.systemFont(ofSize: 28, weight: .medium).adjustedFont
        TimeRemainingLabel.appearance().normalTextColor = .defaultPrimaryText
        TimeRemainingLabel.appearance().trafficHeavyColor = #colorLiteral(red:0.91, green:0.20, blue:0.25, alpha:1.0)
        TimeRemainingLabel.appearance().trafficLowColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        TimeRemainingLabel.appearance().trafficModerateColor = #colorLiteral(red:0.95, green:0.65, blue:0.31, alpha:1.0)
        TimeRemainingLabel.appearance().trafficSevereColor = #colorLiteral(red: 0.7705719471, green: 0.1753477752, blue: 0.1177056804, alpha: 1)
        TimeRemainingLabel.appearance().trafficUnknownColor = .defaultPrimaryText
        TopBannerView.appearance().backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        UserPuckCourseView.appearance().puckColor = #colorLiteral(red: 0.149, green: 0.239, blue: 0.341, alpha: 1)
        UserPuckCourseView.appearance().stalePuckColor = #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1)
        UserHaloCourseView.appearance().haloColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5)
        UserHaloCourseView.appearance().haloRingColor = #colorLiteral(red: 0.149, green: 0.239, blue: 0.341, alpha: 0.3)
        UserHaloCourseView.appearance().haloRadius = 100.0
        WayNameLabel.appearance().normalFont = UIFont.systemFont(ofSize:20, weight: .medium).adjustedFont
        WayNameLabel.appearance().normalTextColor = #colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)
        WayNameLabel.appearance().roadShieldBlackColor = .roadShieldBlackColor
        WayNameLabel.appearance().roadShieldBlueColor = .roadShieldBlueColor
        WayNameLabel.appearance().roadShieldGreenColor = .roadShieldGreenColor
        WayNameLabel.appearance().roadShieldRedColor = .roadShieldRedColor
        WayNameLabel.appearance().roadShieldWhiteColor = .roadShieldWhiteColor
        WayNameLabel.appearance().roadShieldYellowColor = .roadShieldYellowColor
        WayNameLabel.appearance().roadShieldOrangeColor = .roadShieldOrangeColor
        WayNameLabel.appearance().roadShieldDefaultColor = .roadShieldDefaultColor
        WayNameView.appearance().backgroundColor = UIColor.defaultRouteLayer.withAlphaComponent(0.85)
        WayNameView.appearance().borderColor = UIColor.defaultRouteCasing.withAlphaComponent(0.8)
        WayNameView.appearance().borderWidth = 1.0
        StepsTableHeaderView.appearance().tintColor = #colorLiteral(red: 0.9675388083, green: 0.9675388083, blue: 0.9675388083, alpha: 1)
        StepsTableHeaderView.appearance().normalTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
        UILabel.appearance(whenContainedInInstancesOf: [FeedbackViewController.self]).backgroundColor = .white
        UILabel.appearance(whenContainedInInstancesOf: [FeedbackViewController.self]).textColor = .black
        FeedbackStyleView.appearance(whenContainedInInstancesOf: [FeedbackViewController.self]).backgroundColor = .white
        FeedbackCollectionView.appearance().backgroundColor = .white
        FeedbackCollectionView.appearance().cellColor = .black
        
        #if swift(>=5.5)
        if #available(iOS 15.0, *) {
            UITableView.appearance(whenContainedInInstancesOf: [StepsViewController.self]).sectionHeaderTopPadding = 0.0
        }
        #endif
    }
    
    @available(iOS 12.0, *)
    func setCarPlayInstructionsStyling(for traitCollection: UITraitCollection?) {
        guard let traitCollection = traitCollection,
              traitCollection.userInterfaceIdiom == .carPlay else { return }
        
        let carPlayTraitCollection = UITraitCollection(userInterfaceIdiom: .carPlay)
        
        // On CarPlay, `ExitView` and `GenericRouteShield` styling depends on `UIUserInterfaceStyle`,
        // which was set on CarPlay external screen.
        // In case if it was set to `UIUserInterfaceStyle.light` white color will be used, otherwise
        // black.
        // Due to iOS issue (`UIScreen.screens` returns CarPlay screen `traitCollection`
        // property of which returns incorrect value), this property has to be taken from callbacks
        // similar to: `UITraitEnvironment.traitCollectionDidChange(_:)`, or by creating `UITraitCollection`
        // directly.
        switch traitCollection.userInterfaceStyle {
        case .dark:
            let defaultColor = UIColor.white
            
            let carPlayDarkTraitCollection = UITraitCollection(traitsFrom: [
                carPlayTraitCollection,
                UITraitCollection(userInterfaceStyle: .dark)
            ])
            
            ExitView.appearance(for: carPlayDarkTraitCollection).backgroundColor = .clear
            ExitView.appearance(for: carPlayDarkTraitCollection).borderWidth = 1.0
            ExitView.appearance(for: carPlayDarkTraitCollection).cornerRadius = 5.0
            ExitView.appearance(for: carPlayDarkTraitCollection).foregroundColor = defaultColor
            ExitView.appearance(for: carPlayDarkTraitCollection).borderColor = defaultColor
            
            GenericRouteShield.appearance(for: carPlayDarkTraitCollection).backgroundColor = .clear
            GenericRouteShield.appearance(for: carPlayDarkTraitCollection).borderWidth = 1.0
            GenericRouteShield.appearance(for: carPlayDarkTraitCollection).cornerRadius = 5.0
            GenericRouteShield.appearance(for: carPlayDarkTraitCollection).foregroundColor = defaultColor
            GenericRouteShield.appearance(for: carPlayDarkTraitCollection).borderColor = defaultColor
        case .light, .unspecified:
            let defaultColor = UIColor.black
            
            let carPlayLightTraitCollection = UITraitCollection(traitsFrom: [
                carPlayTraitCollection,
                UITraitCollection(userInterfaceStyle: .light)
            ])
            
            ExitView.appearance(for: carPlayLightTraitCollection).backgroundColor = .clear
            ExitView.appearance(for: carPlayLightTraitCollection).borderWidth = 1.0
            ExitView.appearance(for: carPlayLightTraitCollection).cornerRadius = 5.0
            ExitView.appearance(for: carPlayLightTraitCollection).foregroundColor = defaultColor
            ExitView.appearance(for: carPlayLightTraitCollection).borderColor = defaultColor
            
            GenericRouteShield.appearance(for: carPlayLightTraitCollection).backgroundColor = .clear
            GenericRouteShield.appearance(for: carPlayLightTraitCollection).borderWidth = 1.0
            GenericRouteShield.appearance(for: carPlayLightTraitCollection).cornerRadius = 5.0
            GenericRouteShield.appearance(for: carPlayLightTraitCollection).foregroundColor = defaultColor
            GenericRouteShield.appearance(for: carPlayLightTraitCollection).borderColor = defaultColor
        @unknown default:
            fatalError("Unknown userInterfaceStyle.")
        }
    }
    
    func setDefaultCarPlayInstructionsStyling() {
        let defaultColor = UIColor.black
        let carPlayTraitCollection = UITraitCollection(userInterfaceIdiom: .carPlay)
        
        ExitView.appearance(for: carPlayTraitCollection).foregroundColor = defaultColor
        ExitView.appearance(for: carPlayTraitCollection).borderColor = defaultColor
        
        GenericRouteShield.appearance(for: carPlayTraitCollection).foregroundColor = defaultColor
        GenericRouteShield.appearance(for: carPlayTraitCollection).borderColor = defaultColor
    }
}
