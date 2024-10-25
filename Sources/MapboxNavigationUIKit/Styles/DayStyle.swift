import MapboxMaps
@_spi(MapboxInternal) import MapboxNavigationCore
import UIKit

/// The light style for Mapbox Navigation SDK.
open class DayStyle: Style {
    public required init() {
        super.init()

        mapStyleURL = URL(string: StyleURI.light.rawValue)!
        previewMapStyleURL = mapStyleURL
        styleType = .day

        statusBarStyle = .darkContent
    }

    override open func apply() {
        super.apply()

        // General styling
        if let color = UIApplication.shared.delegate?.window??.tintColor {
            tintColor = color
        } else {
            tintColor = .defaultTintColor
        }

        let phoneTraitCollection = UITraitCollection(userInterfaceIdiom: .phone)
        let padTraitCollection = UITraitCollection(userInterfaceIdiom: .pad)
        let carPlayTraitCollection = UITraitCollection(userInterfaceIdiom: .carPlay)

        // Style is applied similarly on iPhone and iPad. Since it's possible to change appearance on CarPlay, style
        // for it is applied separately.
        if traitCollection.containsTraits(in: phoneTraitCollection) || traitCollection
            .containsTraits(in: padTraitCollection)
        {
            applyPhoneOrPadStyling(for: phoneTraitCollection)
            applyPhoneOrPadStyling(for: padTraitCollection)
        } else if traitCollection.containsTraits(in: carPlayTraitCollection) {
            applyCarPlayStyling()
        }
    }

    /// Applies default style for `.phone` and `.pad` trait collections.
    ///
    /// Beware that ``ExitView`` and ``GenericRouteShield`` directly access appearance values while caching their
    /// styles.
    func applyPhoneOrPadStyling(for traitCollection: UITraitCollection) {
        StepsBackgroundView.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)

        StepInstructionsView.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 0.9675388083, green: 0.9675388083, blue: 0.9675388083, alpha: 1)
        StepListIndicatorView.appearance(for: traitCollection).gradientColors = [#colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1), #colorLiteral(red: 0.6274509804, green: 0.6274509804, blue: 0.6274509804, alpha: 1), #colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1)]
        StepTableViewCell.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 0.9675388083, green: 0.9675388083, blue: 0.9675388083, alpha: 1)
        UITableView.appearance(for: traitCollection, whenContainedInInstancesOf: [StepsViewController.self])
            .backgroundColor = #colorLiteral(red: 0.9675388083, green: 0.9675388083, blue: 0.9675388083, alpha: 1)

        StepsTableHeaderView.appearance(for: traitCollection).tintColor = #colorLiteral(red: 0.9675388083, green: 0.9675388083, blue: 0.9675388083, alpha: 1)
        StepsTableHeaderView.appearance(for: traitCollection).normalTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)

#if swift(>=5.5)
        if #available(iOS 15.0, *) {
            UITableView.appearance(for: traitCollection, whenContainedInInstancesOf: [StepsViewController.self])
                .sectionHeaderTopPadding = 0.0
        }
#endif

        UILabel.appearance(for: traitCollection, whenContainedInInstancesOf: [FeedbackViewController.self])
            .backgroundColor = .white
        UILabel.appearance(for: traitCollection, whenContainedInInstancesOf: [FeedbackViewController.self])
            .textColor = .black
        FeedbackStyleView.appearance(for: traitCollection, whenContainedInInstancesOf: [FeedbackViewController.self])
            .backgroundColor = .white
        FeedbackCollectionView.appearance(for: traitCollection).backgroundColor = .white
        FeedbackCollectionView.appearance(for: traitCollection).cellColor = .black

        DismissButton.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        DismissButton.appearance(for: traitCollection).textColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
        DismissButton.appearance(for: traitCollection).textFont = UIFont.systemFont(ofSize: 20.0, weight: .medium)
            .adjustedFont

        EndOfRouteButton.appearance(for: traitCollection).textColor = .darkGray
        EndOfRouteButton.appearance(for: traitCollection).textFont = .systemFont(ofSize: 15.0)
        EndOfRouteContentView.appearance(for: traitCollection).backgroundColor = .white
        EndOfRouteStaticLabel.appearance(for: traitCollection).normalFont = .systemFont(ofSize: 14.0)
        EndOfRouteStaticLabel.appearance(for: traitCollection).normalTextColor = #colorLiteral(red: 0.217173934, green: 0.3645851612, blue: 0.489295125, alpha: 1)
        EndOfRouteTitleLabel.appearance(for: traitCollection).normalFont = .systemFont(ofSize: 36.0)
        EndOfRouteTitleLabel.appearance(for: traitCollection).normalTextColor = .black
        EndOfRouteCommentView.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        EndOfRouteCommentView.appearance(for: traitCollection).normalTextColor = #colorLiteral(red: 0.1205472574, green: 0.2422055006, blue: 0.3489340544, alpha: 1)
        EndOfRouteCommentView.appearance(for: traitCollection).tintColor = #colorLiteral(red: 0.1205472574, green: 0.2422055006, blue: 0.3489340544, alpha: 1)

        PrimaryLabel.appearance(for: traitCollection).normalFont = UIFont.systemFont(ofSize: 30.0, weight: .medium)
            .adjustedFont
        PrimaryLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self])
            .normalTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
        PrimaryLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardView.self])
            .normalTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
        PrimaryLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardView.self])
            .textColorHighlighted = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        PrimaryLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardView.self])
            .normalFont = UIFont.boldSystemFont(ofSize: 24.0).adjustedFont
        PrimaryLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [StepInstructionsView.self])
            .normalTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)

        SecondaryLabel.appearance(for: traitCollection).normalFont = UIFont.systemFont(ofSize: 26.0, weight: .medium)
            .adjustedFont
        SecondaryLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self])
            .normalTextColor = #colorLiteral(red: 0.2156862745, green: 0.2156862745, blue: 0.2156862745, alpha: 1)
        SecondaryLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardView.self])
            .normalTextColor = #colorLiteral(red: 0.2156862745, green: 0.2156862745, blue: 0.2156862745, alpha: 1)
        SecondaryLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardView.self])
            .textColorHighlighted = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        SecondaryLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardView.self])
            .normalFont = UIFont.boldSystemFont(ofSize: 18.0).adjustedFont
        SecondaryLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [StepInstructionsView.self])
            .normalTextColor = #colorLiteral(red: 0.2156862745, green: 0.2156862745, blue: 0.2156862745, alpha: 1)

        InstructionLabel.appearance(for: traitCollection).roadShieldBlackColor = .roadShieldBlackColor
        InstructionLabel.appearance(for: traitCollection).roadShieldBlueColor = .roadShieldBlueColor
        InstructionLabel.appearance(for: traitCollection).roadShieldGreenColor = .roadShieldGreenColor
        InstructionLabel.appearance(for: traitCollection).roadShieldRedColor = .roadShieldRedColor
        InstructionLabel.appearance(for: traitCollection).roadShieldWhiteColor = .roadShieldWhiteColor
        InstructionLabel.appearance(for: traitCollection).roadShieldYellowColor = .roadShieldYellowColor
        InstructionLabel.appearance(for: traitCollection).roadShieldOrangeColor = .roadShieldOrangeColor
        InstructionLabel.appearance(for: traitCollection).roadShieldDefaultColor = .roadShieldDefaultColor

        WayNameLabel.appearance(for: traitCollection).normalFont = UIFont.systemFont(ofSize: 20.0, weight: .medium)
            .adjustedFont
        WayNameLabel.appearance(for: traitCollection).normalTextColor = #colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)
        WayNameLabel.appearance(for: traitCollection).roadShieldBlackColor = .roadShieldBlackColor
        WayNameLabel.appearance(for: traitCollection).roadShieldBlueColor = .roadShieldBlueColor
        WayNameLabel.appearance(for: traitCollection).roadShieldGreenColor = .roadShieldGreenColor
        WayNameLabel.appearance(for: traitCollection).roadShieldRedColor = .roadShieldRedColor
        WayNameLabel.appearance(for: traitCollection).roadShieldWhiteColor = .roadShieldWhiteColor
        WayNameLabel.appearance(for: traitCollection).roadShieldYellowColor = .roadShieldYellowColor
        WayNameLabel.appearance(for: traitCollection).roadShieldOrangeColor = .roadShieldOrangeColor
        WayNameLabel.appearance(for: traitCollection).roadShieldDefaultColor = .roadShieldDefaultColor

        WayNameView.appearance(for: traitCollection).backgroundColor = UIColor.defaultRouteLayer
            .withAlphaComponent(0.85)
        WayNameView.appearance(for: traitCollection).borderColor = UIColor.defaultRouteCasing.withAlphaComponent(0.8)
        WayNameView.appearance(for: traitCollection).borderWidth = 1.0

        Task { @MainActor in
            NavigationMapView.appearance(for: traitCollection).maneuverArrowColor = .defaultManeuverArrow
            NavigationMapView.appearance(for: traitCollection).maneuverArrowStrokeColor = .defaultManeuverArrowStroke
            NavigationMapView.appearance(for: traitCollection).routeAlternateColor = .defaultAlternateLine
            NavigationMapView.appearance(for: traitCollection).routeCasingColor = .defaultRouteCasing
            NavigationMapView.appearance(for: traitCollection).routeAlternateCasingColor = .defaultAlternateLineCasing
            NavigationMapView.appearance(for: traitCollection).routeAnnotationColor = .defaultRouteAnnotationColor
            NavigationMapView.appearance(for: traitCollection)
                .routeAnnotationSelectedColor = .defaultSelectedRouteAnnotationColor
            NavigationMapView.appearance(for: traitCollection)
                .routeAnnotationTextColor = .defaultRouteAnnotationTextColor
            NavigationMapView.appearance(for: traitCollection)
                .routeAnnotationSelectedTextColor = .defaultSelectedRouteAnnotationTextColor
            NavigationMapView.appearance(for: traitCollection)
                .routeAnnotationMoreTimeTextColor = .defaultRouteAnnotationMoreTimeTextColor
            NavigationMapView.appearance(for: traitCollection)
                .routeAnnotationLessTimeTextColor = .defaultRouteAnnotationLessTimeTextColor
            NavigationMapView.appearance(for: traitCollection)
                .waypointColor = .defaultWaypointColor
            NavigationMapView.appearance(for: traitCollection)
                .waypointStrokeColor = .defaultWaypointStrokeColor
        }

        DistanceLabel.appearance(for: traitCollection).unitFont = UIFont.systemFont(ofSize: 14.0, weight: .medium)
            .adjustedFont
        DistanceLabel.appearance(for: traitCollection).valueFont = UIFont.systemFont(ofSize: 22.0, weight: .medium)
            .adjustedFont
        DistanceLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self])
            .unitTextColor = #colorLiteral(red: 0.6274509804, green: 0.6274509804, blue: 0.6274509804, alpha: 1)
        DistanceLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self])
            .valueTextColor = #colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1)
        DistanceLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardView.self])
            .valueTextColor = #colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1)
        DistanceLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardView.self])
            .unitTextColor = #colorLiteral(red: 0.6274509804, green: 0.6274509804, blue: 0.6274509804, alpha: 1)
        DistanceLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardView.self])
            .unitFont = UIFont.systemFont(ofSize: 16.0).adjustedFont
        DistanceLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardView.self])
            .valueFont = UIFont.boldSystemFont(ofSize: 20.0).adjustedFont
        DistanceLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardView.self])
            .unitTextColorHighlighted = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        DistanceLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardView.self])
            .valueTextColorHighlighted = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        DistanceLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [StepInstructionsView.self])
            .unitTextColor = #colorLiteral(red: 0.6274509804, green: 0.6274509804, blue: 0.6274509804, alpha: 1)
        DistanceLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [StepInstructionsView.self])
            .valueTextColor = #colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1)

        SpeedLimitView.appearance(for: traitCollection).signBackColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        SpeedLimitView.appearance(for: traitCollection).textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        SpeedLimitView.appearance(for: traitCollection).regulatoryBorderColor = #colorLiteral(red: 0.800, green: 0, blue: 0, alpha: 1)

        InstructionsCardContainerView.appearance(
            for: traitCollection,
            whenContainedInInstancesOf: [InstructionsCardCell.self]
        ).customBackgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        InstructionsCardContainerView.appearance(
            for: traitCollection,
            whenContainedInInstancesOf: [InstructionsCardCell.self]
        ).highlightedBackgroundColor = #colorLiteral(red: 0.26, green: 0.39, blue: 0.98, alpha: 1.0)
        InstructionsCardContainerView.appearance(
            for: traitCollection,
            whenContainedInInstancesOf: [InstructionsCardCell.self]
        ).separatorColor = #colorLiteral(red: 0.737254902, green: 0.7960784314, blue: 0.8705882353, alpha: 1)
        InstructionsCardContainerView.appearance(
            for: traitCollection,
            whenContainedInInstancesOf: [InstructionsCardCell.self]
        ).highlightedSeparatorColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        InstructionsCardContainerView.appearance(
            for: traitCollection,
            whenContainedInInstancesOf: [InstructionsCardCell.self]
        ).clipsToBounds = true
        InstructionsCardContainerView.appearance(
            for: traitCollection,
            whenContainedInInstancesOf: [InstructionsCardCell.self]
        ).cornerRadius = 20.0

        // On iOS, for Day style, regardless of currently used `UIUserInterfaceStyle`, `ExitView` and
        // `GenericRouteShield` use black color as a default one.
        ExitView.appearance(for: traitCollection).backgroundColor = .clear
        ExitView.appearance(for: traitCollection).borderWidth = 1.0
        ExitView.appearance(for: traitCollection).cornerRadius = 5.0
        ExitView.appearance(for: traitCollection).foregroundColor = .black
        ExitView.appearance(for: traitCollection).borderColor = .black
        ExitView.appearance(for: traitCollection).highlightColor = .white

        GenericRouteShield.appearance(for: traitCollection).backgroundColor = .clear
        GenericRouteShield.appearance(for: traitCollection).borderWidth = 1.0
        GenericRouteShield.appearance(for: traitCollection).cornerRadius = 5.0
        GenericRouteShield.appearance(for: traitCollection).foregroundColor = .black
        GenericRouteShield.appearance(for: traitCollection).borderColor = .black
        GenericRouteShield.appearance(for: traitCollection).highlightColor = .white

        UILabel.appearance(for: traitCollection, whenContainedInInstancesOf: [FeedbackViewController.self])
            .backgroundColor = .white
        UILabel.appearance(for: traitCollection, whenContainedInInstancesOf: [FeedbackViewController.self])
            .textColor = .black
        FeedbackStyleView.appearance(for: traitCollection, whenContainedInInstancesOf: [FeedbackViewController.self])
            .backgroundColor = .white
        FeedbackCollectionView.appearance(for: traitCollection).backgroundColor = .white
        FeedbackCollectionView.appearance(for: traitCollection).cellColor = .black
        FeedbackSubtypeCollectionViewCell.appearance(for: traitCollection).normalCircleColor = .white
        FeedbackSubtypeCollectionViewCell.appearance(for: traitCollection).normalCircleOutlineColor = .darkText
        FeedbackSubtypeCollectionViewCell.appearance(for: traitCollection).selectedCircleColor = #colorLiteral(red: 0, green: 0.47843137, blue: 1, alpha: 1)

        let regularAndRegularSizeClassTraitCollection = UITraitCollection(traitsFrom: [
            traitCollection,
            UITraitCollection(verticalSizeClass: .regular),
            UITraitCollection(horizontalSizeClass: .regular),
        ])

        let regularAndCompactSizeClassTraitCollection = UITraitCollection(traitsFrom: [
            traitCollection,
            UITraitCollection(verticalSizeClass: .regular),
            UITraitCollection(horizontalSizeClass: .compact),
        ])

        let compactAndRegularSizeClassTraitCollection = UITraitCollection(traitsFrom: [
            traitCollection,
            UITraitCollection(verticalSizeClass: .compact),
            UITraitCollection(horizontalSizeClass: .regular),
        ])

        let compactAndCompactSizeClassTraitCollection = UITraitCollection(traitsFrom: [
            traitCollection,
            UITraitCollection(verticalSizeClass: .compact),
            UITraitCollection(horizontalSizeClass: .compact),
        ])

        TimeRemainingLabel.appearance(for: regularAndRegularSizeClassTraitCollection).normalFont = UIFont.systemFont(
            ofSize: 28.0,
            weight: .medium
        ).adjustedFont
        TimeRemainingLabel.appearance(for: regularAndCompactSizeClassTraitCollection).normalFont = UIFont.systemFont(
            ofSize: 28.0,
            weight: .medium
        ).adjustedFont
        TimeRemainingLabel.appearance(for: compactAndRegularSizeClassTraitCollection).normalFont = UIFont.systemFont(
            ofSize: 28.0,
            weight: .medium
        ).adjustedFont
        TimeRemainingLabel.appearance(for: compactAndCompactSizeClassTraitCollection).normalFont = UIFont.systemFont(
            ofSize: 18.0,
            weight: .medium
        ).adjustedFont
        TimeRemainingLabel.appearance(for: traitCollection).normalFont = UIFont
            .systemFont(ofSize: 28.0, weight: .medium).adjustedFont
        TimeRemainingLabel.appearance(for: traitCollection).normalTextColor = .defaultPrimaryTextColor
        TimeRemainingLabel.appearance(for: traitCollection).trafficHeavyColor = #colorLiteral(red: 0.91, green: 0.20, blue: 0.25, alpha: 1.0)
        TimeRemainingLabel.appearance(for: traitCollection).trafficLowColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        TimeRemainingLabel.appearance(for: traitCollection).trafficModerateColor = #colorLiteral(red: 0.95, green: 0.65, blue: 0.31, alpha: 1.0)
        TimeRemainingLabel.appearance(for: traitCollection).trafficSevereColor = #colorLiteral(red: 0.7705719471, green: 0.1753477752, blue: 0.1177056804, alpha: 1)
        TimeRemainingLabel.appearance(for: traitCollection).trafficUnknownColor = .defaultPrimaryTextColor

        TimeRemainingLabel.appearance(
            for: regularAndRegularSizeClassTraitCollection,
            whenContainedInInstancesOf: [RoutePreviewViewController.self]
        ).normalFont = UIFont
            .systemFont(
                ofSize: 28.0,
                weight: .medium
            ).adjustedFont
        TimeRemainingLabel.appearance(
            for: regularAndCompactSizeClassTraitCollection,
            whenContainedInInstancesOf: [RoutePreviewViewController.self]
        ).normalFont = UIFont
            .systemFont(
                ofSize: 28.0,
                weight: .medium
            ).adjustedFont
        TimeRemainingLabel.appearance(
            for: compactAndRegularSizeClassTraitCollection,
            whenContainedInInstancesOf: [RoutePreviewViewController.self]
        ).normalFont = UIFont
            .systemFont(
                ofSize: 28.0,
                weight: .medium
            ).adjustedFont
        TimeRemainingLabel.appearance(
            for: compactAndCompactSizeClassTraitCollection,
            whenContainedInInstancesOf: [RoutePreviewViewController.self]
        ).normalFont = UIFont
            .systemFont(
                ofSize: 20.0,
                weight: .medium
            ).adjustedFont

        StepsTableHeaderView.appearance(for: traitCollection).tintColor = #colorLiteral(red: 0.9675388083, green: 0.9675388083, blue: 0.9675388083, alpha: 1)
        StepsTableHeaderView.appearance(for: traitCollection).normalTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)

        Button.appearance(for: traitCollection).textColor = .defaultPrimaryTextColor

        CancelButton.appearance(for: traitCollection).tintColor = .defaultPrimaryTextColor

        PreviewButton.appearance(for: traitCollection).tintColor = .defaultPrimaryTextColor
        StartButton.appearance(for: traitCollection).tintColor = .defaultPrimaryTextColor

        FloatingButton.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        FloatingButton.appearance(for: traitCollection).tintColor = tintColor
        FloatingButton.appearance(for: traitCollection).borderWidth = Style.defaultBorderWidth
        FloatingButton.appearance(for: traitCollection).borderColor = .defaultBorderColor

        DistanceRemainingLabel.appearance(for: traitCollection).normalFont = UIFont.systemFont(
            ofSize: 18.0,
            weight: .medium
        ).adjustedFont
        DistanceRemainingLabel.appearance(for: traitCollection).normalTextColor = #colorLiteral(red: 0.431372549, green: 0.431372549, blue: 0.431372549, alpha: 1)

        DistanceRemainingLabel.appearance(
            for: traitCollection,
            whenContainedInInstancesOf: [RoutePreviewViewController.self]
        )
        .normalFont = UIFont.systemFont(
            ofSize: 15.0,
            weight: .medium
        ).adjustedFont
        DistanceRemainingLabel.appearance(
            for: traitCollection,
            whenContainedInInstancesOf: [RoutePreviewViewController.self]
        )
        .normalTextColor = .defaultPrimaryTextColor

        NavigationView.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 0.764706, green: 0.752941, blue: 0.733333, alpha: 1)

        SeparatorView.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 0.737254902, green: 0.7960784314, blue: 0.8705882353, alpha: 1)
        SeparatorView.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardView.self])
            .backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)

        RatingControl.appearance(for: traitCollection).normalColor = #colorLiteral(red: 0.8508961797, green: 0.8510394692, blue: 0.850877285, alpha: 1)
        RatingControl.appearance(for: traitCollection).selectedColor = #colorLiteral(red: 0.1205472574, green: 0.2422055006, blue: 0.3489340544, alpha: 1)

        ResumeButton.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        ResumeButton.appearance(for: traitCollection).tintColor = .defaultPrimaryTextColor
        ResumeButton.appearance(for: traitCollection).borderColor = #colorLiteral(red: 0.737254902, green: 0.7960784314, blue: 0.8705882353, alpha: 1)
        ResumeButton.appearance(for: traitCollection).borderWidth = Style.defaultBorderWidth
        ResumeButton.appearance(for: traitCollection).cornerRadius = 5.0

        BackButton.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        BackButton.appearance(for: traitCollection).borderColor = #colorLiteral(red: 0.737254902, green: 0.7960784314, blue: 0.8705882353, alpha: 1)
        BackButton.appearance(for: traitCollection).borderWidth = Style.defaultBorderWidth
        BackButton.appearance(for: traitCollection).cornerRadius = 5.0
        BackButton.appearance(for: traitCollection).textFont = UIFont.systemFont(ofSize: 15, weight: .regular)
        BackButton.appearance(for: traitCollection).tintColor = .defaultPrimaryTextColor

        NextBannerView.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 0.9675388083, green: 0.9675388083, blue: 0.9675388083, alpha: 1)
        NextBannerView
            .appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardContainerView.self])
            .backgroundColor = #colorLiteral(red: 0.9675388083, green: 0.9675388083, blue: 0.9675388083, alpha: 1)

        StatusView.appearance(for: traitCollection).backgroundColor = UIColor.black.withAlphaComponent(2.0 / 3.0)

        TopBannerView.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        BottomBannerView.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        BottomPaddingView.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        InstructionsBannerView.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)

        ArrivalTimeLabel.appearance(for: traitCollection).normalFont = UIFont.systemFont(ofSize: 18.0, weight: .medium)
            .adjustedFont
        ArrivalTimeLabel.appearance(for: traitCollection).normalTextColor = .defaultPrimaryTextColor

        ArrivalTimeLabel.appearance(
            for: traitCollection,
            whenContainedInInstancesOf: [RoutePreviewViewController.self]
        ).normalFont = UIFont
            .systemFont(
                ofSize: 15.0,
                weight: .medium
            ).adjustedFont
        ArrivalTimeLabel.appearance(
            for: traitCollection,
            whenContainedInInstancesOf: [RoutePreviewViewController.self]
        )
        .normalTextColor = .defaultPrimaryTextColor

        DestinationLabel.appearance(for: regularAndRegularSizeClassTraitCollection).normalFont = UIFont.systemFont(
            ofSize: 25.0,
            weight: .medium
        ).adjustedFont
        DestinationLabel.appearance(for: regularAndCompactSizeClassTraitCollection).normalFont = UIFont.systemFont(
            ofSize: 25.0,
            weight: .medium
        ).adjustedFont
        DestinationLabel.appearance(for: compactAndRegularSizeClassTraitCollection).normalFont = UIFont.systemFont(
            ofSize: 25.0,
            weight: .medium
        ).adjustedFont
        DestinationLabel.appearance(for: compactAndCompactSizeClassTraitCollection).normalFont = UIFont.systemFont(
            ofSize: 18.0,
            weight: .medium
        ).adjustedFont
        DestinationLabel.appearance(for: traitCollection).normalTextColor = .defaultPrimaryTextColor
        DestinationLabel.appearance(for: traitCollection).numberOfLines = 2

        NextInstructionLabel.appearance(for: traitCollection).normalFont = UIFont.systemFont(
            ofSize: 20.0,
            weight: .medium
        ).adjustedFont
        NextInstructionLabel.appearance(for: traitCollection).normalTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
        NextInstructionLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [NextBannerView.self])
            .normalTextColor = UIColor(
                red: 0.15,
                green: 0.24,
                blue: 0.34,
                alpha: 1.0
            )
        NextInstructionLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [NextBannerView.self])
            .textColorHighlighted = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        NextInstructionLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [NextBannerView.self])
            .normalFont = UIFont.systemFont(ofSize: 14.0).adjustedFont

        LaneView.appearance(for: traitCollection).primaryColor = .defaultLaneArrowPrimary
        LaneView.appearance(for: traitCollection).secondaryColor = .defaultLaneArrowSecondary
        LaneView.appearance(for: traitCollection).primaryColorHighlighted = .defaultLaneArrowPrimaryHighlighted
        LaneView.appearance(for: traitCollection).secondaryColorHighlighted = .defaultLaneArrowSecondaryHighlighted

        LanesView.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)

        ManeuverView.appearance(for: traitCollection).backgroundColor = .clear
        ManeuverView.appearance(for: traitCollection).primaryColorHighlighted = .defaultTurnArrowPrimaryHighlighted
        ManeuverView.appearance(for: traitCollection).secondaryColorHighlighted = .defaultTurnArrowSecondaryHighlighted
        ManeuverView.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self])
            .primaryColor = .defaultTurnArrowPrimary
        ManeuverView.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self])
            .secondaryColor = .defaultTurnArrowSecondary
        ManeuverView.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardView.self])
            .primaryColor = .defaultTurnArrowPrimary
        ManeuverView.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsCardView.self])
            .secondaryColor = .defaultTurnArrowSecondary
        ManeuverView.appearance(for: traitCollection, whenContainedInInstancesOf: [NextBannerView.self])
            .primaryColor = .defaultTurnArrowPrimary
        ManeuverView.appearance(for: traitCollection, whenContainedInInstancesOf: [NextBannerView.self])
            .secondaryColor = .defaultTurnArrowSecondary
        ManeuverView.appearance(for: traitCollection, whenContainedInInstancesOf: [StepInstructionsView.self])
            .primaryColor = .defaultTurnArrowPrimary
        ManeuverView.appearance(for: traitCollection, whenContainedInInstancesOf: [StepInstructionsView.self])
            .secondaryColor = .defaultTurnArrowSecondary
    }

    /// Applies default style for CarPlay.
    ///
    /// Since it's possible to apply different appearances on iOS and CarPlay and some views are  re-used on both
    /// platforms, style for iOS and CarPlay views that are common is applied independently.
    func applyCarPlayStyling() {
        let carPlayTraitCollection = UITraitCollection(userInterfaceIdiom: .carPlay)

        // `CarPlayCompassView` appearance styling. `CarPlayCompassView` is only used on CarPlay
        // and is not shared across other platforms.
        CarPlayCompassView.appearance(for: carPlayTraitCollection).backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.6022227113)
        CarPlayCompassView.appearance(for: carPlayTraitCollection).cornerRadius = 4
        CarPlayCompassView.appearance(for: carPlayTraitCollection)
            .borderWidth = 1.0 / (UIScreen.mainCarPlay?.scale ?? 2.0)
        CarPlayCompassView.appearance(for: carPlayTraitCollection).borderColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 0.6009573063)

        // `StylableLabel` is used in `CarPlayCompassView` to show compass direction.
        StylableLabel.appearance(for: carPlayTraitCollection, whenContainedInInstancesOf: [CarPlayCompassView.self])
            .normalFont = UIFont.systemFont(
                ofSize: 12.0,
                weight: .medium
            ).adjustedFont
        StylableLabel.appearance(for: carPlayTraitCollection, whenContainedInInstancesOf: [CarPlayCompassView.self])
            .normalTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)

        PrimaryLabel.appearance(for: carPlayTraitCollection).normalFont = UIFont.systemFont(
            ofSize: 30.0,
            weight: .medium
        ).adjustedFont

        SecondaryLabel.appearance(for: carPlayTraitCollection).normalFont = UIFont.systemFont(
            ofSize: 26.0,
            weight: .medium
        ).adjustedFont

        InstructionLabel.appearance(for: carPlayTraitCollection).roadShieldBlackColor = .roadShieldBlackColor
        InstructionLabel.appearance(for: carPlayTraitCollection).roadShieldBlueColor = .roadShieldBlueColor
        InstructionLabel.appearance(for: carPlayTraitCollection).roadShieldGreenColor = .roadShieldGreenColor
        InstructionLabel.appearance(for: carPlayTraitCollection).roadShieldRedColor = .roadShieldRedColor
        InstructionLabel.appearance(for: carPlayTraitCollection).roadShieldWhiteColor = .roadShieldWhiteColor
        InstructionLabel.appearance(for: carPlayTraitCollection).roadShieldYellowColor = .roadShieldYellowColor
        InstructionLabel.appearance(for: carPlayTraitCollection).roadShieldOrangeColor = .roadShieldOrangeColor
        InstructionLabel.appearance(for: carPlayTraitCollection).roadShieldDefaultColor = .roadShieldDefaultColor

        WayNameLabel.appearance(for: carPlayTraitCollection).normalFont = UIFont.systemFont(
            ofSize: 13.0,
            weight: .medium
        ).adjustedFont
        WayNameLabel.appearance(for: carPlayTraitCollection).normalTextColor = #colorLiteral(red: 0.968627451, green: 0.968627451, blue: 0.968627451, alpha: 1)
        WayNameLabel.appearance(for: carPlayTraitCollection).roadShieldBlackColor = .roadShieldBlackColor
        WayNameLabel.appearance(for: carPlayTraitCollection).roadShieldBlueColor = .roadShieldBlueColor
        WayNameLabel.appearance(for: carPlayTraitCollection).roadShieldGreenColor = .roadShieldGreenColor
        WayNameLabel.appearance(for: carPlayTraitCollection).roadShieldRedColor = .roadShieldRedColor
        WayNameLabel.appearance(for: carPlayTraitCollection).roadShieldWhiteColor = .roadShieldWhiteColor
        WayNameLabel.appearance(for: carPlayTraitCollection).roadShieldYellowColor = .roadShieldYellowColor
        WayNameLabel.appearance(for: carPlayTraitCollection).roadShieldOrangeColor = .roadShieldOrangeColor
        WayNameLabel.appearance(for: carPlayTraitCollection).roadShieldDefaultColor = .roadShieldDefaultColor

        WayNameView.appearance(for: carPlayTraitCollection).backgroundColor = UIColor.defaultRouteLayer
            .withAlphaComponent(0.85)
        WayNameView.appearance(for: carPlayTraitCollection).borderColor = UIColor.defaultRouteCasing
            .withAlphaComponent(0.8)
        WayNameView.appearance(for: carPlayTraitCollection).borderWidth = 1.0

        Task { @MainActor in

            NavigationMapView.appearance(for: carPlayTraitCollection).maneuverArrowColor = .defaultManeuverArrow
            NavigationMapView.appearance(for: carPlayTraitCollection)
                .maneuverArrowStrokeColor = .defaultManeuverArrowStroke
            NavigationMapView.appearance(for: carPlayTraitCollection).routeAlternateColor = .defaultAlternateLine
            NavigationMapView.appearance(for: carPlayTraitCollection).routeCasingColor = .defaultRouteCasing
            NavigationMapView.appearance(for: carPlayTraitCollection)
                .routeAlternateCasingColor = .defaultAlternateLineCasing

            NavigationMapView.appearance(for: carPlayTraitCollection)
                .routeAnnotationColor = .defaultRouteAnnotationColor
            NavigationMapView.appearance(for: carPlayTraitCollection)
                .routeAnnotationSelectedColor = .defaultSelectedRouteAnnotationColor
            NavigationMapView.appearance(for: carPlayTraitCollection).routeAnnotationTextColor = #colorLiteral(red: 0.09803921569, green: 0.09803921569, blue: 0.09803921569, alpha: 1)
            NavigationMapView.appearance(for: carPlayTraitCollection).routeAnnotationSelectedTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
            NavigationMapView.appearance(for: traitCollection)
                .waypointColor = .defaultWaypointColor
            NavigationMapView.appearance(for: traitCollection)
                .waypointStrokeColor = .defaultWaypointStrokeColor
        }

        SpeedLimitView.appearance(for: carPlayTraitCollection).signBackColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        SpeedLimitView.appearance(for: carPlayTraitCollection).textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        SpeedLimitView.appearance(for: carPlayTraitCollection).regulatoryBorderColor = #colorLiteral(red: 0.800, green: 0, blue: 0, alpha: 1)

        ManeuverView.appearance(for: carPlayTraitCollection).backgroundColor = .clear
        ManeuverView.appearance(for: carPlayTraitCollection)
            .primaryColorHighlighted = .defaultTurnArrowPrimaryHighlighted
        ManeuverView.appearance(for: carPlayTraitCollection)
            .secondaryColorHighlighted = .defaultTurnArrowSecondaryHighlighted

        let carPlayLightTraitCollection = UITraitCollection(traitsFrom: [
            carPlayTraitCollection,
            UITraitCollection(userInterfaceStyle: .light),
        ])
        applyCarPlayManeuversStyling(for: carPlayLightTraitCollection)

        let carPlayDarkTraitCollection = UITraitCollection(traitsFrom: [
            carPlayTraitCollection,
            UITraitCollection(userInterfaceStyle: .dark),
        ])
        applyCarPlayManeuversStyling(for: carPlayDarkTraitCollection)
    }

    /// Applies default styling for lane views, exit views and shields on CarPlay versions that support light and dark
    /// appearance changes.
    func applyCarPlayManeuversStyling(for traitCollection: UITraitCollection) {
        // On CarPlay, `ExitView` and `GenericRouteShield` styling depends on `UIUserInterfaceStyle`,
        // which was set on CarPlay external screen.
        // In case if it was set to `UIUserInterfaceStyle.light` white color will be used, otherwise
        // black.
        // Due to iOS issue (`UIScreen.screens` returns CarPlay screen `traitCollection`
        // property of which returns incorrect value), this property has to be taken from callbacks
        // similar to: `UITraitEnvironment.traitCollectionDidChange(_:)`, or by creating `UITraitCollection`
        // directly.
        let defaultInstructionColor: UIColor
        let defaultInstructionHighlightedColor: UIColor

        let defaultLaneViewPrimaryColor: UIColor
        let defaultLaneViewSecondaryColor: UIColor

        let defaultLaneArrowPrimaryHighlightedColor: UIColor
        let defaultLaneArrowSecondaryHighlightedColor: UIColor

        switch traitCollection.userInterfaceStyle {
        case .light, .unspecified:
            defaultInstructionColor = UIColor.black
            defaultInstructionHighlightedColor = UIColor.white

            defaultLaneViewPrimaryColor = .defaultLaneArrowPrimary
            defaultLaneViewSecondaryColor = .defaultLaneArrowSecondary

            defaultLaneArrowPrimaryHighlightedColor = .defaultLaneArrowPrimaryHighlighted
            defaultLaneArrowSecondaryHighlightedColor = .defaultLaneArrowSecondaryHighlighted
        case .dark:
            defaultInstructionColor = UIColor.white
            defaultInstructionHighlightedColor = UIColor.black

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
        ExitView.appearance(for: traitCollection).highlightColor = defaultInstructionHighlightedColor

        GenericRouteShield.appearance(for: traitCollection).backgroundColor = .clear
        GenericRouteShield.appearance(for: traitCollection).borderWidth = 1.0
        GenericRouteShield.appearance(for: traitCollection).cornerRadius = 5.0
        GenericRouteShield.appearance(for: traitCollection).foregroundColor = defaultInstructionColor
        GenericRouteShield.appearance(for: traitCollection).borderColor = defaultInstructionColor
        GenericRouteShield.appearance(for: traitCollection).highlightColor = defaultInstructionHighlightedColor

        LaneView.appearance(for: traitCollection).primaryColor = defaultLaneViewPrimaryColor
        LaneView.appearance(for: traitCollection).secondaryColor = defaultLaneViewSecondaryColor

        LaneView.appearance(for: traitCollection).primaryColorHighlighted = defaultLaneArrowPrimaryHighlightedColor
        LaneView.appearance(for: traitCollection).secondaryColorHighlighted = defaultLaneArrowSecondaryHighlightedColor
    }
}
