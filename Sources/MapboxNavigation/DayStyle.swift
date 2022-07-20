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
        
        if #available(iOS 13.0, *) {
            statusBarStyle = .darkContent
        } else {
            statusBarStyle = .default
        }
    }
    
    open override func apply() {
        super.apply()
        
        // General styling
        if let color = UIApplication.shared.delegate?.window??.tintColor {
            tintColor = color
        } else {
            tintColor = .defaultTint
        }
        
        switch traitCollection.userInterfaceIdiom {
        case .phone:
            let phoneTraitCollection = UITraitCollection(userInterfaceIdiom: .phone)
            
            StepsBackgroundView.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            
            StepInstructionsView.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 0.9675388083, green: 0.9675388083, blue: 0.9675388083, alpha: 1)
            StepListIndicatorView.appearance(for: phoneTraitCollection).gradientColors = [#colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1), #colorLiteral(red: 0.6274509804, green: 0.6274509804, blue: 0.6274509804, alpha: 1), #colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1)]
            StepTableViewCell.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 0.9675388083, green: 0.9675388083, blue: 0.9675388083, alpha: 1)
            UITableView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [StepsViewController.self]).backgroundColor = #colorLiteral(red: 0.9675388083, green: 0.9675388083, blue: 0.9675388083, alpha: 1)
            
            StepsTableHeaderView.appearance(for: phoneTraitCollection).tintColor = #colorLiteral(red: 0.9675388083, green: 0.9675388083, blue: 0.9675388083, alpha: 1)
            StepsTableHeaderView.appearance(for: phoneTraitCollection).normalTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
            
            #if swift(>=5.5)
            if #available(iOS 15.0, *) {
                UITableView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [StepsViewController.self]).sectionHeaderTopPadding = 0.0
            }
            #endif
            
            UILabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [FeedbackViewController.self]).backgroundColor = .white
            UILabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [FeedbackViewController.self]).textColor = .black
            FeedbackStyleView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [FeedbackViewController.self]).backgroundColor = .white
            FeedbackCollectionView.appearance(for: phoneTraitCollection).backgroundColor = .white
            FeedbackCollectionView.appearance(for: phoneTraitCollection).cellColor = .black
            
            DismissButton.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            DismissButton.appearance(for: phoneTraitCollection).textColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
            DismissButton.appearance(for: phoneTraitCollection).textFont = UIFont.systemFont(ofSize: 20.0, weight: .medium).adjustedFont
            
            EndOfRouteButton.appearance(for: phoneTraitCollection).textColor = .darkGray
            EndOfRouteButton.appearance(for: phoneTraitCollection).textFont = .systemFont(ofSize: 15.0)
            EndOfRouteContentView.appearance(for: phoneTraitCollection).backgroundColor = .white
            EndOfRouteStaticLabel.appearance(for: phoneTraitCollection).normalFont = .systemFont(ofSize: 14.0)
            EndOfRouteStaticLabel.appearance(for: phoneTraitCollection).normalTextColor = #colorLiteral(red: 0.217173934, green: 0.3645851612, blue: 0.489295125, alpha: 1)
            EndOfRouteTitleLabel.appearance(for: phoneTraitCollection).normalFont = .systemFont(ofSize: 36.0)
            EndOfRouteTitleLabel.appearance(for: phoneTraitCollection).normalTextColor = .black
            EndOfRouteCommentView.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            EndOfRouteCommentView.appearance(for: phoneTraitCollection).normalTextColor = #colorLiteral(red: 0.1205472574, green: 0.2422055006, blue: 0.3489340544, alpha: 1)
            EndOfRouteCommentView.appearance(for: phoneTraitCollection).tintColor = #colorLiteral(red: 0.1205472574, green: 0.2422055006, blue: 0.3489340544, alpha: 1)
            
            PrimaryLabel.appearance(for: phoneTraitCollection).normalFont = UIFont.systemFont(ofSize: 30.0, weight: .medium).adjustedFont
            PrimaryLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self]).normalTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
            PrimaryLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).normalTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
            PrimaryLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).textColorHighlighted = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            PrimaryLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).normalFont = UIFont.boldSystemFont(ofSize: 24.0).adjustedFont
            PrimaryLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [StepInstructionsView.self]).normalTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
            
            SecondaryLabel.appearance(for: phoneTraitCollection).normalFont = UIFont.systemFont(ofSize: 26.0, weight: .medium).adjustedFont
            SecondaryLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self]).normalTextColor = #colorLiteral(red: 0.2156862745, green: 0.2156862745, blue: 0.2156862745, alpha: 1)
            SecondaryLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).normalTextColor = #colorLiteral(red: 0.2156862745, green: 0.2156862745, blue: 0.2156862745, alpha: 1)
            SecondaryLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).textColorHighlighted = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            SecondaryLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).normalFont = UIFont.boldSystemFont(ofSize: 18.0).adjustedFont
            SecondaryLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [StepInstructionsView.self]).normalTextColor = #colorLiteral(red: 0.2156862745, green: 0.2156862745, blue: 0.2156862745, alpha: 1)
            
            InstructionLabel.appearance(for: phoneTraitCollection).roadShieldBlackColor = .roadShieldBlackColor
            InstructionLabel.appearance(for: phoneTraitCollection).roadShieldBlueColor = .roadShieldBlueColor
            InstructionLabel.appearance(for: phoneTraitCollection).roadShieldGreenColor = .roadShieldGreenColor
            InstructionLabel.appearance(for: phoneTraitCollection).roadShieldRedColor = .roadShieldRedColor
            InstructionLabel.appearance(for: phoneTraitCollection).roadShieldWhiteColor = .roadShieldWhiteColor
            InstructionLabel.appearance(for: phoneTraitCollection).roadShieldYellowColor = .roadShieldYellowColor
            InstructionLabel.appearance(for: phoneTraitCollection).roadShieldOrangeColor = .roadShieldOrangeColor
            InstructionLabel.appearance(for: phoneTraitCollection).roadShieldDefaultColor = .roadShieldDefaultColor
            
            WayNameLabel.appearance(for: phoneTraitCollection).normalFont = UIFont.systemFont(ofSize: 20.0, weight: .medium).adjustedFont
            WayNameLabel.appearance(for: phoneTraitCollection).normalTextColor = #colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)
            WayNameLabel.appearance(for: phoneTraitCollection).roadShieldBlackColor = .roadShieldBlackColor
            WayNameLabel.appearance(for: phoneTraitCollection).roadShieldBlueColor = .roadShieldBlueColor
            WayNameLabel.appearance(for: phoneTraitCollection).roadShieldGreenColor = .roadShieldGreenColor
            WayNameLabel.appearance(for: phoneTraitCollection).roadShieldRedColor = .roadShieldRedColor
            WayNameLabel.appearance(for: phoneTraitCollection).roadShieldWhiteColor = .roadShieldWhiteColor
            WayNameLabel.appearance(for: phoneTraitCollection).roadShieldYellowColor = .roadShieldYellowColor
            WayNameLabel.appearance(for: phoneTraitCollection).roadShieldOrangeColor = .roadShieldOrangeColor
            WayNameLabel.appearance(for: phoneTraitCollection).roadShieldDefaultColor = .roadShieldDefaultColor
            
            WayNameView.appearance(for: phoneTraitCollection).backgroundColor = UIColor.defaultRouteLayer.withAlphaComponent(0.85)
            WayNameView.appearance(for: phoneTraitCollection).borderColor = UIColor.defaultRouteCasing.withAlphaComponent(0.8)
            WayNameView.appearance(for: phoneTraitCollection).borderWidth = 1.0
            
            NavigationMapView.appearance(for: phoneTraitCollection).maneuverArrowColor = .defaultManeuverArrow
            NavigationMapView.appearance(for: phoneTraitCollection).maneuverArrowStrokeColor = .defaultManeuverArrowStroke
            NavigationMapView.appearance(for: phoneTraitCollection).routeAlternateColor = .defaultAlternateLine
            NavigationMapView.appearance(for: phoneTraitCollection).routeCasingColor = .defaultRouteCasing
            NavigationMapView.appearance(for: phoneTraitCollection).traversedRouteColor = .defaultTraversedRouteColor
            NavigationMapView.appearance(for: phoneTraitCollection).trafficHeavyColor = .trafficHeavy
            NavigationMapView.appearance(for: phoneTraitCollection).trafficLowColor = .trafficLow
            NavigationMapView.appearance(for: phoneTraitCollection).trafficModerateColor = .trafficModerate
            NavigationMapView.appearance(for: phoneTraitCollection).trafficSevereColor = .trafficSevere
            NavigationMapView.appearance(for: phoneTraitCollection).trafficUnknownColor = .trafficUnknown
            NavigationMapView.appearance(for: phoneTraitCollection).alternativeTrafficHeavyColor = .alternativeTrafficHeavy
            NavigationMapView.appearance(for: phoneTraitCollection).alternativeTrafficLowColor = .alternativeTrafficLow
            NavigationMapView.appearance(for: phoneTraitCollection).alternativeTrafficModerateColor = .alternativeTrafficModerate
            NavigationMapView.appearance(for: phoneTraitCollection).alternativeTrafficSevereColor = .alternativeTrafficSevere
            NavigationMapView.appearance(for: phoneTraitCollection).alternativeTrafficUnknownColor = .alternativeTrafficUnknown
            NavigationMapView.appearance(for: phoneTraitCollection).buildingDefaultColor = .defaultBuildingColor
            NavigationMapView.appearance(for: phoneTraitCollection).buildingHighlightColor = .defaultBuildingHighlightColor
            NavigationMapView.appearance(for: phoneTraitCollection).routeDurationAnnotationColor = .routeDurationAnnotationColor
            NavigationMapView.appearance(for: phoneTraitCollection).routeDurationAnnotationSelectedColor = .selectedRouteDurationAnnotationColor
            NavigationMapView.appearance(for: phoneTraitCollection).routeDurationAnnotationFontNames = UIFont.defaultNavigationSymbolLayerFontNames
            NavigationMapView.appearance(for: phoneTraitCollection).routeDurationAnnotationTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
            NavigationMapView.appearance(for: phoneTraitCollection).routeDurationAnnotationSelectedTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            
            UserPuckCourseView.appearance(for: phoneTraitCollection).puckColor = #colorLiteral(red: 0.149, green: 0.239, blue: 0.341, alpha: 1)
            
            UserHaloCourseView.appearance(for: phoneTraitCollection).haloColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5)
            UserHaloCourseView.appearance(for: phoneTraitCollection).haloRingColor = #colorLiteral(red: 0.149, green: 0.239, blue: 0.341, alpha: 0.3)
            UserHaloCourseView.appearance(for: phoneTraitCollection).haloRadius = 100.0
            
            DistanceLabel.appearance(for: phoneTraitCollection).unitFont = UIFont.systemFont(ofSize: 14.0, weight: .medium).adjustedFont
            DistanceLabel.appearance(for: phoneTraitCollection).valueFont = UIFont.systemFont(ofSize: 22.0, weight: .medium).adjustedFont
            DistanceLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self]).unitTextColor = #colorLiteral(red: 0.6274509804, green: 0.6274509804, blue: 0.6274509804, alpha: 1)
            DistanceLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self]).valueTextColor = #colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1)
            DistanceLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).valueTextColor = #colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1)
            DistanceLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).unitTextColor = #colorLiteral(red: 0.6274509804, green: 0.6274509804, blue: 0.6274509804, alpha: 1)
            DistanceLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).unitFont = UIFont.systemFont(ofSize: 16.0).adjustedFont
            DistanceLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).valueFont = UIFont.boldSystemFont(ofSize: 20.0).adjustedFont
            DistanceLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).unitTextColorHighlighted = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            DistanceLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).valueTextColorHighlighted = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            DistanceLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [StepInstructionsView.self]).unitTextColor = #colorLiteral(red: 0.6274509804, green: 0.6274509804, blue: 0.6274509804, alpha: 1)
            DistanceLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [StepInstructionsView.self]).valueTextColor = #colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1)
            
            SpeedLimitView.appearance(for: phoneTraitCollection).signBackColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            SpeedLimitView.appearance(for: phoneTraitCollection).textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            SpeedLimitView.appearance(for: phoneTraitCollection).regulatoryBorderColor = #colorLiteral(red: 0.800, green: 0, blue: 0, alpha: 1)
            
            InstructionsCardContainerView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardCell.self]).customBackgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            InstructionsCardContainerView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardCell.self]).highlightedBackgroundColor = #colorLiteral(red: 0.26, green: 0.39, blue: 0.98, alpha: 1.0)
            InstructionsCardContainerView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardCell.self]).separatorColor = #colorLiteral(red: 0.737254902, green: 0.7960784314, blue: 0.8705882353, alpha: 1)
            InstructionsCardContainerView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardCell.self]).highlightedSeparatorColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            InstructionsCardContainerView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardCell.self]).clipsToBounds = true
            InstructionsCardContainerView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardCell.self]).cornerRadius = 20.0
            
            // On iOS, for Day style, regardless of currently used `UIUserInterfaceStyle`, `ExitView` and
            // `GenericRouteShield` use black color as a default one.
            ExitView.appearance(for: phoneTraitCollection).backgroundColor = .clear
            ExitView.appearance(for: phoneTraitCollection).borderWidth = 1.0
            ExitView.appearance(for: phoneTraitCollection).cornerRadius = 5.0
            ExitView.appearance(for: phoneTraitCollection).foregroundColor = .black
            ExitView.appearance(for: phoneTraitCollection).borderColor = .black
            
            GenericRouteShield.appearance(for: phoneTraitCollection).backgroundColor = .clear
            GenericRouteShield.appearance(for: phoneTraitCollection).borderWidth = 1.0
            GenericRouteShield.appearance(for: phoneTraitCollection).cornerRadius = 5.0
            GenericRouteShield.appearance(for: phoneTraitCollection).foregroundColor = .black
            GenericRouteShield.appearance(for: phoneTraitCollection).borderColor = .black
            
            UILabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [FeedbackViewController.self]).backgroundColor = .white
            UILabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [FeedbackViewController.self]).textColor = .black
            FeedbackStyleView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [FeedbackViewController.self]).backgroundColor = .white
            FeedbackCollectionView.appearance(for: phoneTraitCollection).backgroundColor = .white
            FeedbackCollectionView.appearance(for: phoneTraitCollection).cellColor = .black
            FeedbackSubtypeCollectionViewCell.appearance(for: phoneTraitCollection).normalCircleColor = .white
            FeedbackSubtypeCollectionViewCell.appearance(for: phoneTraitCollection).normalCircleOutlineColor = .darkText
            FeedbackSubtypeCollectionViewCell.appearance(for: phoneTraitCollection).selectedCircleColor = #colorLiteral(red: 0, green: 0.47843137, blue: 1, alpha: 1)
            
            let regularAndRegularSizeClassPhoneTraitCollection = UITraitCollection(traitsFrom: [
                UITraitCollection(userInterfaceIdiom: .phone),
                UITraitCollection(verticalSizeClass: .regular),
                UITraitCollection(horizontalSizeClass: .regular)
            ])
            
            let regularAndCompactSizeClassPhoneTraitCollection = UITraitCollection(traitsFrom: [
                UITraitCollection(userInterfaceIdiom: .phone),
                UITraitCollection(verticalSizeClass: .regular),
                UITraitCollection(horizontalSizeClass: .compact)
            ])
            
            let compactAndRegularSizeClassPhoneTraitCollection = UITraitCollection(traitsFrom: [
                UITraitCollection(userInterfaceIdiom: .phone),
                UITraitCollection(verticalSizeClass: .compact),
                UITraitCollection(horizontalSizeClass: .regular)
            ])
            
            let compactAndCompactSizeClassPhoneTraitCollection = UITraitCollection(traitsFrom: [
                UITraitCollection(userInterfaceIdiom: .phone),
                UITraitCollection(verticalSizeClass: .compact),
                UITraitCollection(horizontalSizeClass: .compact)
            ])
            
            TimeRemainingLabel.appearance(for: regularAndRegularSizeClassPhoneTraitCollection).normalFont = UIFont.systemFont(ofSize: 28.0, weight: .medium).adjustedFont
            TimeRemainingLabel.appearance(for: regularAndCompactSizeClassPhoneTraitCollection).normalFont = UIFont.systemFont(ofSize: 28.0, weight: .medium).adjustedFont
            TimeRemainingLabel.appearance(for: compactAndRegularSizeClassPhoneTraitCollection).normalFont = UIFont.systemFont(ofSize: 28.0, weight: .medium).adjustedFont
            TimeRemainingLabel.appearance(for: compactAndCompactSizeClassPhoneTraitCollection).normalFont = UIFont.systemFont(ofSize: 18.0, weight: .medium).adjustedFont
            TimeRemainingLabel.appearance(for: phoneTraitCollection).normalFont = UIFont.systemFont(ofSize: 28.0, weight: .medium).adjustedFont
            TimeRemainingLabel.appearance(for: phoneTraitCollection).normalTextColor = .defaultPrimaryText
            TimeRemainingLabel.appearance(for: phoneTraitCollection).trafficHeavyColor = #colorLiteral(red:0.91, green:0.20, blue:0.25, alpha:1.0)
            TimeRemainingLabel.appearance(for: phoneTraitCollection).trafficLowColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
            TimeRemainingLabel.appearance(for: phoneTraitCollection).trafficModerateColor = #colorLiteral(red:0.95, green:0.65, blue:0.31, alpha:1.0)
            TimeRemainingLabel.appearance(for: phoneTraitCollection).trafficSevereColor = #colorLiteral(red: 0.7705719471, green: 0.1753477752, blue: 0.1177056804, alpha: 1)
            TimeRemainingLabel.appearance(for: phoneTraitCollection).trafficUnknownColor = .defaultPrimaryText
            
            StepsTableHeaderView.appearance(for: phoneTraitCollection).tintColor = #colorLiteral(red: 0.9675388083, green: 0.9675388083, blue: 0.9675388083, alpha: 1)
            StepsTableHeaderView.appearance(for: phoneTraitCollection).normalTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
            
            Button.appearance(for: phoneTraitCollection).textColor = .defaultPrimaryText
            
            CancelButton.appearance(for: phoneTraitCollection).tintColor = .defaultPrimaryText
            
            FloatingButton.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            FloatingButton.appearance(for: phoneTraitCollection).tintColor = tintColor
            
            DistanceRemainingLabel.appearance(for: phoneTraitCollection).normalFont = UIFont.systemFont(ofSize: 18.0, weight: .medium).adjustedFont
            DistanceRemainingLabel.appearance(for: phoneTraitCollection).normalTextColor = #colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1)
            
            NavigationView.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 0.764706, green: 0.752941, blue: 0.733333, alpha: 1)
            
            SeparatorView.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 0.737254902, green: 0.7960784314, blue: 0.8705882353, alpha: 1)
            SeparatorView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            
            RatingControl.appearance(for: phoneTraitCollection).normalColor = #colorLiteral(red: 0.8508961797, green: 0.8510394692, blue: 0.850877285, alpha: 1)
            RatingControl.appearance(for: phoneTraitCollection).selectedColor = #colorLiteral(red: 0.1205472574, green: 0.2422055006, blue: 0.3489340544, alpha: 1)
            
            ResumeButton.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            ResumeButton.appearance(for: phoneTraitCollection).tintColor = .defaultPrimaryText
            ResumeButton.appearance(for: phoneTraitCollection).borderColor = #colorLiteral(red: 0.737254902, green: 0.7960784314, blue: 0.8705882353, alpha: 1)
            ResumeButton.appearance(for: phoneTraitCollection).borderWidth = 1 / UIScreen.main.scale
            ResumeButton.appearance(for: phoneTraitCollection).cornerRadius = 5.0
            
            NextBannerView.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 0.9675388083, green: 0.9675388083, blue: 0.9675388083, alpha: 1)
            NextBannerView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardContainerView.self]).backgroundColor = #colorLiteral(red: 0.9675388083, green: 0.9675388083, blue: 0.9675388083, alpha: 1)
            
            StatusView.appearance(for: phoneTraitCollection).backgroundColor = UIColor.black.withAlphaComponent(2.0 / 3.0)
            
            TopBannerView.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            BottomBannerView.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            BottomPaddingView.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            InstructionsBannerView.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            
            ArrivalTimeLabel.appearance(for: phoneTraitCollection).normalFont = UIFont.systemFont(ofSize: 18.0, weight: .medium).adjustedFont
            ArrivalTimeLabel.appearance(for: phoneTraitCollection).normalTextColor = .defaultPrimaryText
            
            NextInstructionLabel.appearance(for: phoneTraitCollection).normalFont = UIFont.systemFont(ofSize: 20.0, weight: .medium).adjustedFont
            NextInstructionLabel.appearance(for: phoneTraitCollection).normalTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
            NextInstructionLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [NextBannerView.self]).normalTextColor = UIColor(red: 0.15, green: 0.24, blue: 0.34, alpha: 1.0)
            NextInstructionLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [NextBannerView.self]).textColorHighlighted = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            NextInstructionLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [NextBannerView.self]).normalFont = UIFont.systemFont(ofSize: 14.0).adjustedFont
            
            LaneView.appearance(for: phoneTraitCollection).primaryColor = .defaultLaneArrowPrimary
            LaneView.appearance(for: phoneTraitCollection).secondaryColor = .defaultLaneArrowSecondary
            LaneView.appearance(for: phoneTraitCollection).primaryColorHighlighted = .defaultLaneArrowPrimaryHighlighted
            LaneView.appearance(for: phoneTraitCollection).secondaryColorHighlighted = .defaultLaneArrowSecondaryHighlighted
            
            LanesView.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)
            
            ManeuverView.appearance(for: phoneTraitCollection).backgroundColor = .clear
            ManeuverView.appearance(for: phoneTraitCollection).primaryColorHighlighted = .defaultTurnArrowPrimaryHighlighted
            ManeuverView.appearance(for: phoneTraitCollection).secondaryColorHighlighted = .defaultTurnArrowSecondaryHighlighted
            ManeuverView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self]).primaryColor = .defaultTurnArrowPrimary
            ManeuverView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self]).secondaryColor = .defaultTurnArrowSecondary
            ManeuverView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).primaryColor = .defaultTurnArrowPrimary
            ManeuverView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).secondaryColor = .defaultTurnArrowSecondary
            ManeuverView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [NextBannerView.self]).primaryColor = .defaultTurnArrowPrimary
            ManeuverView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [NextBannerView.self]).secondaryColor = .defaultTurnArrowSecondary
            ManeuverView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [StepInstructionsView.self]).primaryColor = .defaultTurnArrowPrimary
            ManeuverView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [StepInstructionsView.self]).secondaryColor = .defaultTurnArrowSecondary
        case .carPlay:
            let carPlayTraitCollection = UITraitCollection(userInterfaceIdiom: .carPlay)
            
            // `CarPlayCompassView` appearance styling. `CarPlayCompassView` is only used on CarPlay
            // and is not shared across other platforms.
            CarPlayCompassView.appearance(for: carPlayTraitCollection).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.6022227113)
            CarPlayCompassView.appearance(for: carPlayTraitCollection).cornerRadius = 4
            CarPlayCompassView.appearance(for: carPlayTraitCollection).borderWidth = 1.0 / (UIScreen.mainCarPlay?.scale ?? 2.0)
            CarPlayCompassView.appearance(for: carPlayTraitCollection).borderColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 0.6009573063)
            
            // `StylableLabel` is used in `CarPlayCompassView` to show compass direction.
            StylableLabel.appearance(for: carPlayTraitCollection, whenContainedInInstancesOf: [CarPlayCompassView.self]).normalFont = UIFont.systemFont(ofSize: 12.0, weight: .medium).adjustedFont
            StylableLabel.appearance(for: carPlayTraitCollection, whenContainedInInstancesOf: [CarPlayCompassView.self]).normalTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
            
            PrimaryLabel.appearance(for: carPlayTraitCollection).normalFont = UIFont.systemFont(ofSize: 30.0, weight: .medium).adjustedFont
            
            SecondaryLabel.appearance(for: carPlayTraitCollection).normalFont = UIFont.systemFont(ofSize: 26.0, weight: .medium).adjustedFont
            
            InstructionLabel.appearance(for: carPlayTraitCollection).roadShieldBlackColor = .roadShieldBlackColor
            InstructionLabel.appearance(for: carPlayTraitCollection).roadShieldBlueColor = .roadShieldBlueColor
            InstructionLabel.appearance(for: carPlayTraitCollection).roadShieldGreenColor = .roadShieldGreenColor
            InstructionLabel.appearance(for: carPlayTraitCollection).roadShieldRedColor = .roadShieldRedColor
            InstructionLabel.appearance(for: carPlayTraitCollection).roadShieldWhiteColor = .roadShieldWhiteColor
            InstructionLabel.appearance(for: carPlayTraitCollection).roadShieldYellowColor = .roadShieldYellowColor
            InstructionLabel.appearance(for: carPlayTraitCollection).roadShieldOrangeColor = .roadShieldOrangeColor
            InstructionLabel.appearance(for: carPlayTraitCollection).roadShieldDefaultColor = .roadShieldDefaultColor
            
            WayNameLabel.appearance(for: carPlayTraitCollection).normalFont = UIFont.systemFont(ofSize: 15.0, weight: .medium).adjustedFont
            WayNameLabel.appearance(for: carPlayTraitCollection).normalTextColor = #colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)
            WayNameLabel.appearance(for: carPlayTraitCollection).roadShieldBlackColor = .roadShieldBlackColor
            WayNameLabel.appearance(for: carPlayTraitCollection).roadShieldBlueColor = .roadShieldBlueColor
            WayNameLabel.appearance(for: carPlayTraitCollection).roadShieldGreenColor = .roadShieldGreenColor
            WayNameLabel.appearance(for: carPlayTraitCollection).roadShieldRedColor = .roadShieldRedColor
            WayNameLabel.appearance(for: carPlayTraitCollection).roadShieldWhiteColor = .roadShieldWhiteColor
            WayNameLabel.appearance(for: carPlayTraitCollection).roadShieldYellowColor = .roadShieldYellowColor
            WayNameLabel.appearance(for: carPlayTraitCollection).roadShieldOrangeColor = .roadShieldOrangeColor
            WayNameLabel.appearance(for: carPlayTraitCollection).roadShieldDefaultColor = .roadShieldDefaultColor
            
            WayNameView.appearance(for: carPlayTraitCollection).backgroundColor = UIColor.defaultRouteLayer.withAlphaComponent(0.85)
            WayNameView.appearance(for: carPlayTraitCollection).borderColor = UIColor.defaultRouteCasing.withAlphaComponent(0.8)
            WayNameView.appearance(for: carPlayTraitCollection).borderWidth = 1.0
            
            NavigationMapView.appearance(for: carPlayTraitCollection).maneuverArrowColor = .defaultManeuverArrow
            NavigationMapView.appearance(for: carPlayTraitCollection).maneuverArrowStrokeColor = .defaultManeuverArrowStroke
            NavigationMapView.appearance(for: carPlayTraitCollection).routeAlternateColor = .defaultAlternateLine
            NavigationMapView.appearance(for: carPlayTraitCollection).routeCasingColor = .defaultRouteCasing
            NavigationMapView.appearance(for: carPlayTraitCollection).traversedRouteColor = .defaultTraversedRouteColor
            NavigationMapView.appearance(for: carPlayTraitCollection).trafficHeavyColor = .trafficHeavy
            NavigationMapView.appearance(for: carPlayTraitCollection).trafficLowColor = .trafficLow
            NavigationMapView.appearance(for: carPlayTraitCollection).trafficModerateColor = .trafficModerate
            NavigationMapView.appearance(for: carPlayTraitCollection).trafficSevereColor = .trafficSevere
            NavigationMapView.appearance(for: carPlayTraitCollection).trafficUnknownColor = .trafficUnknown
            NavigationMapView.appearance(for: carPlayTraitCollection).alternativeTrafficHeavyColor = .alternativeTrafficHeavy
            NavigationMapView.appearance(for: carPlayTraitCollection).alternativeTrafficLowColor = .alternativeTrafficLow
            NavigationMapView.appearance(for: carPlayTraitCollection).alternativeTrafficModerateColor = .alternativeTrafficModerate
            NavigationMapView.appearance(for: carPlayTraitCollection).alternativeTrafficSevereColor = .alternativeTrafficSevere
            NavigationMapView.appearance(for: carPlayTraitCollection).alternativeTrafficUnknownColor = .alternativeTrafficUnknown
            NavigationMapView.appearance(for: carPlayTraitCollection).buildingDefaultColor = .defaultBuildingColor
            NavigationMapView.appearance(for: carPlayTraitCollection).buildingHighlightColor = .defaultBuildingHighlightColor
            NavigationMapView.appearance(for: carPlayTraitCollection).routeDurationAnnotationColor = .routeDurationAnnotationColor
            NavigationMapView.appearance(for: carPlayTraitCollection).routeDurationAnnotationSelectedColor = .selectedRouteDurationAnnotationColor
            NavigationMapView.appearance(for: carPlayTraitCollection).routeDurationAnnotationFontNames = UIFont.defaultNavigationSymbolLayerFontNames
            NavigationMapView.appearance(for: carPlayTraitCollection).routeDurationAnnotationTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
            NavigationMapView.appearance(for: carPlayTraitCollection).routeDurationAnnotationSelectedTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            
            UserPuckCourseView.appearance(for: carPlayTraitCollection).puckColor = #colorLiteral(red: 0.149, green: 0.239, blue: 0.341, alpha: 1)
            
            UserHaloCourseView.appearance(for: carPlayTraitCollection).haloColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5)
            UserHaloCourseView.appearance(for: carPlayTraitCollection).haloRingColor = #colorLiteral(red: 0.149, green: 0.239, blue: 0.341, alpha: 0.3)
            UserHaloCourseView.appearance(for: carPlayTraitCollection).haloRadius = 100.0
            
            SpeedLimitView.appearance(for: carPlayTraitCollection).signBackColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            SpeedLimitView.appearance(for: carPlayTraitCollection).textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
            SpeedLimitView.appearance(for: carPlayTraitCollection).regulatoryBorderColor = #colorLiteral(red: 0.800, green: 0, blue: 0, alpha: 1)
            
            ManeuverView.appearance(for: carPlayTraitCollection).backgroundColor = .clear
            ManeuverView.appearance(for: carPlayTraitCollection).primaryColorHighlighted = .defaultTurnArrowPrimaryHighlighted
            ManeuverView.appearance(for: carPlayTraitCollection).secondaryColorHighlighted = .defaultTurnArrowSecondaryHighlighted
            
            // In case if CarPlay supports `UIUserInterfaceStyle` styling will be applied for a
            // `UITraitCollection`, which contains both `UIUserInterfaceIdiom` and `UIUserInterfaceStyle`.
            // If not, `UITraitCollection` will only contain `UIUserInterfaceIdiom`.
            if #available(iOS 12.0, *) {
                let carPlayLightTraitCollection = UITraitCollection(traitsFrom: [
                    carPlayTraitCollection,
                    UITraitCollection(userInterfaceStyle: .light)
                ])
                applyCarPlayStyling(for: carPlayLightTraitCollection)
                
                let carPlayDarkTraitCollection = UITraitCollection(traitsFrom: [
                    carPlayTraitCollection,
                    UITraitCollection(userInterfaceStyle: .dark)
                ])
                applyCarPlayStyling(for: carPlayDarkTraitCollection)
            } else {
                applyDefaultCarPlayStyling()
            }
        default:
            break
        }
    }
    
    @available(iOS 12.0, *)
    func applyCarPlayStyling(for traitCollection: UITraitCollection) {
        // On CarPlay, `ExitView` and `GenericRouteShield` styling depends on `UIUserInterfaceStyle`,
        // which was set on CarPlay external screen.
        // In case if it was set to `UIUserInterfaceStyle.light` white color will be used, otherwise
        // black.
        // Due to iOS issue (`UIScreen.screens` returns CarPlay screen `traitCollection`
        // property of which returns incorrect value), this property has to be taken from callbacks
        // similar to: `UITraitEnvironment.traitCollectionDidChange(_:)`, or by creating `UITraitCollection`
        // directly.
        let defaultInstructionColor: UIColor
        
        let defaultLaneViewPrimaryColor: UIColor
        let defaultLaneViewSecondaryColor: UIColor
        
        let defaultLaneArrowPrimaryHighlightedColor: UIColor
        let defaultLaneArrowSecondaryHighlightedColor: UIColor
        
        switch traitCollection.userInterfaceStyle {
        case .light, .unspecified:
            defaultInstructionColor = UIColor.black
            
            defaultLaneViewPrimaryColor = .defaultLaneArrowPrimary
            defaultLaneViewSecondaryColor = .defaultLaneArrowSecondary
            
            defaultLaneArrowPrimaryHighlightedColor = .defaultLaneArrowPrimaryHighlighted
            defaultLaneArrowSecondaryHighlightedColor = .defaultLaneArrowSecondaryHighlighted
        case .dark:
            defaultInstructionColor = UIColor.white
            
            defaultLaneViewPrimaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            defaultLaneViewSecondaryColor = #colorLiteral(red: 0.4198532104, green: 0.4398920536, blue: 0.4437610507, alpha: 1)
            
            defaultLaneArrowPrimaryHighlightedColor = .defaultLaneArrowPrimaryHighlighted
            defaultLaneArrowSecondaryHighlightedColor = .defaultLaneArrowSecondaryHighlighted
        @unknown default:
            fatalError("Unknown userInterfaceStyle.")
        }
        
        ExitView.appearance(for: traitCollection).backgroundColor = .clear
        ExitView.appearance(for: traitCollection).borderWidth = 1.0
        ExitView.appearance(for: traitCollection).cornerRadius = 5.0
        ExitView.appearance(for: traitCollection).foregroundColor = defaultInstructionColor
        ExitView.appearance(for: traitCollection).borderColor = defaultInstructionColor

        GenericRouteShield.appearance(for: traitCollection).backgroundColor = .clear
        GenericRouteShield.appearance(for: traitCollection).borderWidth = 1.0
        GenericRouteShield.appearance(for: traitCollection).cornerRadius = 5.0
        GenericRouteShield.appearance(for: traitCollection).foregroundColor = defaultInstructionColor
        GenericRouteShield.appearance(for: traitCollection).borderColor = defaultInstructionColor

        LaneView.appearance(for: traitCollection).primaryColor = defaultLaneViewPrimaryColor
        LaneView.appearance(for: traitCollection).secondaryColor = defaultLaneViewSecondaryColor

        LaneView.appearance(for: traitCollection).primaryColorHighlighted = defaultLaneArrowPrimaryHighlightedColor
        LaneView.appearance(for: traitCollection).secondaryColorHighlighted = defaultLaneArrowSecondaryHighlightedColor
    }
    
    func applyDefaultCarPlayStyling() {
        let defaultColor = UIColor.black
        let carPlayTraitCollection = UITraitCollection(userInterfaceIdiom: .carPlay)
        
        ExitView.appearance(for: carPlayTraitCollection).foregroundColor = defaultColor
        ExitView.appearance(for: carPlayTraitCollection).borderColor = defaultColor
        
        GenericRouteShield.appearance(for: carPlayTraitCollection).foregroundColor = defaultColor
        GenericRouteShield.appearance(for: carPlayTraitCollection).borderColor = defaultColor
        
        LaneView.appearance(for: carPlayTraitCollection).primaryColor = .defaultLaneArrowPrimary
        LaneView.appearance(for: carPlayTraitCollection).secondaryColor = .defaultLaneArrowSecondary
        
        LaneView.appearance(for: carPlayTraitCollection).primaryColorHighlighted = .defaultLaneArrowPrimaryHighlighted
        LaneView.appearance(for: carPlayTraitCollection).secondaryColorHighlighted = .defaultLaneArrowSecondaryHighlighted
    }
}
