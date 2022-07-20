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
        
        switch traitCollection.userInterfaceIdiom {
        case .phone:
            let phoneTraitCollection = UITraitCollection(userInterfaceIdiom: .phone)
            
            SpeedLimitView.appearance(for: phoneTraitCollection).signBackColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
            
            FloatingButton.appearance(for: phoneTraitCollection).backgroundColor = backgroundColor
            FloatingButton.appearance(for: phoneTraitCollection).tintColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
            
            InstructionsCardContainerView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardCell.self]).customBackgroundColor = backgroundColor
            InstructionsCardContainerView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardCell.self]).separatorColor = #colorLiteral(red: 0.3764705882, green: 0.4901960784, blue: 0.6117647059, alpha: 0.796599912)
            InstructionsCardContainerView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardCell.self]).highlightedSeparatorColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            
            // On iOS, for Night style, regardless of currently used `UIUserInterfaceStyle`, `ExitView` and
            // `GenericRouteShield` use white color as a default one.
            ExitView.appearance(for: phoneTraitCollection).foregroundColor = .white
            ExitView.appearance(for: phoneTraitCollection).borderColor = .white
            
            GenericRouteShield.appearance(for: phoneTraitCollection).foregroundColor = .white
            GenericRouteShield.appearance(for: phoneTraitCollection).borderColor = .white
            
            DistanceRemainingLabel.appearance(for: phoneTraitCollection).normalTextColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
            
            ArrivalTimeLabel.appearance(for: phoneTraitCollection).normalTextColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
            
            Button.appearance(for: phoneTraitCollection).textColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
            CancelButton.appearance(for: phoneTraitCollection).tintColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
            
            DismissButton.appearance(for: phoneTraitCollection).backgroundColor = backgroundColor
            DismissButton.appearance(for: phoneTraitCollection).textColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
            
            LaneView.appearance(for: phoneTraitCollection).primaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            LaneView.appearance(for: phoneTraitCollection).secondaryColor = #colorLiteral(red: 0.4198532104, green: 0.4398920536, blue: 0.4437610507, alpha: 1)
            
            LanesView.appearance(for: phoneTraitCollection).backgroundColor = backgroundColor
            
            StepsBackgroundView.appearance(for: phoneTraitCollection).backgroundColor = backgroundColor
            StepsTableHeaderView.appearance(for: phoneTraitCollection).tintColor = #colorLiteral(red: 0.103291966, green: 0.1482483149, blue: 0.2006777823, alpha: 1)
            StepsTableHeaderView.appearance(for: phoneTraitCollection).normalTextColor = #colorLiteral(red: 0.9996390939, green: 1, blue: 0.9997561574, alpha: 1)
            
            StepInstructionsView.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 0.103291966, green: 0.1482483149, blue: 0.2006777823, alpha: 1)
            StepTableViewCell.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 0.103291966, green: 0.1482483149, blue: 0.2006777823, alpha: 1)
            UITableView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [StepsViewController.self]).backgroundColor = #colorLiteral(red: 0.103291966, green: 0.1482483149, blue: 0.2006777823, alpha: 1)
            
            UILabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [FeedbackViewController.self]).backgroundColor = .black
            UILabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [FeedbackViewController.self]).textColor = .white
            
            FeedbackStyleView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [FeedbackViewController.self]).backgroundColor = .black
            FeedbackCollectionView.appearance(for: phoneTraitCollection).backgroundColor = .black
            FeedbackCollectionView.appearance(for: phoneTraitCollection).cellColor = .white
            
            UILabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [FeedbackViewController.self]).backgroundColor = .black
            UILabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [FeedbackViewController.self]).textColor = .white
            FeedbackStyleView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [FeedbackViewController.self]).backgroundColor = .black
            FeedbackCollectionView.appearance(for: phoneTraitCollection).backgroundColor = .black
            FeedbackCollectionView.appearance(for: phoneTraitCollection).cellColor = .white
            FeedbackSubtypeCollectionViewCell.appearance(for: phoneTraitCollection).normalCircleColor = .black
            FeedbackSubtypeCollectionViewCell.appearance(for: phoneTraitCollection).normalCircleOutlineColor = .lightText
            
            TopBannerView.appearance(for: phoneTraitCollection).backgroundColor = backgroundColor
            BottomBannerView.appearance(for: phoneTraitCollection).backgroundColor = backgroundColor
            BottomPaddingView.appearance(for: phoneTraitCollection).backgroundColor = backgroundColor
            InstructionsBannerView.appearance(for: phoneTraitCollection).backgroundColor = backgroundColor
            
            WayNameView.appearance(for: phoneTraitCollection).borderColor = #colorLiteral(red: 0.2802129388, green: 0.3988235593, blue: 0.5260632038, alpha: 1)
            WayNameLabel.appearance(for: phoneTraitCollection).roadShieldBlackColor = #colorLiteral(red: 0.08, green: 0.09, blue: 0.12, alpha: 1)
            WayNameLabel.appearance(for: phoneTraitCollection).roadShieldBlueColor = #colorLiteral(red: 0.18, green: 0.26, blue: 0.66, alpha: 1)
            WayNameLabel.appearance(for: phoneTraitCollection).roadShieldGreenColor = #colorLiteral(red: 0.07, green: 0.51, blue: 0.22, alpha: 1)
            WayNameLabel.appearance(for: phoneTraitCollection).roadShieldRedColor = #colorLiteral(red: 0.86, green: 0.06, blue: 0.06, alpha: 1)
            WayNameLabel.appearance(for: phoneTraitCollection).roadShieldWhiteColor = #colorLiteral(red: 0.78, green: 0.78, blue: 0.78, alpha: 1)
            WayNameLabel.appearance(for: phoneTraitCollection).roadShieldYellowColor = #colorLiteral(red: 1.0, green: 0.85, blue: 0.08, alpha: 1)
            WayNameLabel.appearance(for: phoneTraitCollection).roadShieldDefaultColor = #colorLiteral(red: 0.08, green: 0.09, blue: 0.12, alpha: 1)
            
            ManeuverView.appearance(for: phoneTraitCollection).backgroundColor = .clear
            ManeuverView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self]).primaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            ManeuverView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self]).secondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.3)
            ManeuverView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [NextBannerView.self]).primaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            ManeuverView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [NextBannerView.self]).secondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.3)
            ManeuverView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [StepInstructionsView.self]).primaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            ManeuverView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [StepInstructionsView.self]).secondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.3)
            ManeuverView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).primaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            ManeuverView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).secondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.3)
            
            DistanceLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self]).unitTextColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
            DistanceLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self]).valueTextColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
            DistanceLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [StepInstructionsView.self]).unitTextColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
            DistanceLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [StepInstructionsView.self]).valueTextColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
            DistanceLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).unitTextColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
            DistanceLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).valueTextColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
            
            EndOfRouteButton.appearance(for: phoneTraitCollection).textColor = .white
            EndOfRouteCommentView.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 0.1875049942, green: 0.2981707989, blue: 0.4181857639, alpha: 1)
            EndOfRouteCommentView.appearance(for: phoneTraitCollection).normalTextColor = .white
            EndOfRouteContentView.appearance(for: phoneTraitCollection).backgroundColor = backgroundColor
            EndOfRouteStaticLabel.appearance(for: phoneTraitCollection).alpha = 1.0
            EndOfRouteStaticLabel.appearance(for: phoneTraitCollection).textColor = UIColor.white.withAlphaComponent(0.9)
            EndOfRouteTitleLabel.appearance(for: phoneTraitCollection).textColor = .white
            
            TimeRemainingLabel.appearance(for: phoneTraitCollection).normalTextColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
            TimeRemainingLabel.appearance(for: phoneTraitCollection).trafficUnknownColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
            
            NavigationMapView.appearance(for: phoneTraitCollection).routeAlternateColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
            NavigationMapView.appearance(for: phoneTraitCollection).buildingDefaultColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            NavigationMapView.appearance(for: phoneTraitCollection).buildingHighlightColor = #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1)
            
            NavigationView.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 0.0470588, green: 0.0509804, blue: 0.054902, alpha: 1)
            
            PrimaryLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self]).normalTextColor = #colorLiteral(red: 0.9996390939, green: 1, blue: 0.9997561574, alpha: 1)
            PrimaryLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [StepInstructionsView.self]).normalTextColor = #colorLiteral(red: 0.9996390939, green: 1, blue: 0.9997561574, alpha: 1)
            PrimaryLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).normalTextColor = #colorLiteral(red: 0.9996390939, green: 1, blue: 0.9997561574, alpha: 1)
            
            SecondaryLabel.appearance(for: phoneTraitCollection).normalFont = UIFont.systemFont(ofSize: 26.0, weight: .medium).adjustedFont
            SecondaryLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).normalTextColor = #colorLiteral(red: 0.7349056005, green: 0.7675836682, blue: 0.8063536286, alpha: 1)
            SecondaryLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self]).normalTextColor = #colorLiteral(red: 0.7349056005, green: 0.7675836682, blue: 0.8063536286, alpha: 1)
            SecondaryLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [StepInstructionsView.self]).normalTextColor = #colorLiteral(red: 0.7349056005, green: 0.7675836682, blue: 0.8063536286, alpha: 1)
            
            InstructionLabel.appearance(for: phoneTraitCollection).roadShieldBlackColor = #colorLiteral(red: 0.08, green: 0.09, blue: 0.12, alpha: 1)
            InstructionLabel.appearance(for: phoneTraitCollection).roadShieldBlueColor = #colorLiteral(red: 0.18, green: 0.26, blue: 0.66, alpha: 1)
            InstructionLabel.appearance(for: phoneTraitCollection).roadShieldGreenColor = #colorLiteral(red: 0.07, green: 0.51, blue: 0.22, alpha: 1)
            InstructionLabel.appearance(for: phoneTraitCollection).roadShieldRedColor = #colorLiteral(red: 0.86, green: 0.06, blue: 0.06, alpha: 1)
            InstructionLabel.appearance(for: phoneTraitCollection).roadShieldWhiteColor = #colorLiteral(red: 0.78, green: 0.78, blue: 0.78, alpha: 1)
            InstructionLabel.appearance(for: phoneTraitCollection).roadShieldYellowColor = #colorLiteral(red: 1.0, green: 0.85, blue: 0.08, alpha: 1)
            InstructionLabel.appearance(for: phoneTraitCollection).roadShieldDefaultColor = #colorLiteral(red: 0.08, green: 0.09, blue: 0.12, alpha: 1)
            
            SeparatorView.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 0.3764705882, green: 0.4901960784, blue: 0.6117647059, alpha: 0.796599912)
            SeparatorView.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [InstructionsCardView.self]).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            
            RatingControl.appearance(for: phoneTraitCollection).normalColor = #colorLiteral(red: 0.149668334, green: 0.1680230035, blue: 0.1472480238, alpha: 1)
            RatingControl.appearance(for: phoneTraitCollection).selectedColor = #colorLiteral(red: 0.9803059896, green: 0.9978019022, blue: 1, alpha: 1)
            
            ResumeButton.appearance(for: phoneTraitCollection).backgroundColor = backgroundColor
            ResumeButton.appearance(for: phoneTraitCollection).tintColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
            ResumeButton.appearance(for: phoneTraitCollection).borderColor = #colorLiteral(red: 0.3764705882, green: 0.4901960784, blue: 0.6117647059, alpha: 0.796599912)
            
            NextBannerView.appearance(for: phoneTraitCollection).backgroundColor = #colorLiteral(red: 0.103291966, green: 0.1482483149, blue: 0.2006777823, alpha: 1)
            
            NextInstructionLabel.appearance(for: phoneTraitCollection).normalTextColor = #colorLiteral(red: 0.984, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
            NextInstructionLabel.appearance(for: phoneTraitCollection, whenContainedInInstancesOf: [NextBannerView.self]).normalTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        case .carPlay:
            let carPlayTraitCollection = UITraitCollection(userInterfaceIdiom: .carPlay)
            
            SpeedLimitView.appearance(for: carPlayTraitCollection).signBackColor = #colorLiteral(red: 0.7991961837, green: 0.8232284188, blue: 0.8481693864, alpha: 1)
            
            // `CarPlayCompassView` appearance styling. `CarPlayCompassView` is only used on CarPlay
            // and is not shared across other platforms.
            CarPlayCompassView.appearance(for: carPlayTraitCollection).backgroundColor = backgroundColor
            
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
        default:
            break
        }
    }
}
