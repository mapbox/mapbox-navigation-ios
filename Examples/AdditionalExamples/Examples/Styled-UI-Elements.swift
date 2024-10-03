/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios
 To learn more about the SDK, see our docs: https://docs.mapbox.com/ios/navigation
 */

import CoreLocation
import Foundation
import MapboxDirections
import MapboxNavigationCore
import MapboxNavigationUIKit
import UIKit

final class CustomStyleUIElements: UIViewController {
    private let mapboxNavigationProvider = MapboxNavigationProvider(
        coreConfig: .init(
            locationSource: simulationIsEnabled ? .simulation(
                initialLocation: .init(
                    latitude: 37.77440680146262,
                    longitude: -122.43539772352648
                )
            ) : .live
        )
    )
    private var mapboxNavigation: MapboxNavigation {
        mapboxNavigationProvider.mapboxNavigation
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let origin = CLLocationCoordinate2DMake(37.77440680146262, -122.43539772352648)
        let destination = CLLocationCoordinate2DMake(37.76556957793795, -122.42409811526268)
        let options = NavigationRouteOptions(coordinates: [origin, destination])

        let request = mapboxNavigation.routingProvider().calculateRoutes(options: options)

        Task {
            switch await request.result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let navigationRoutes):
                let navigationOptions = NavigationOptions(
                    mapboxNavigation: mapboxNavigation,
                    voiceController: mapboxNavigationProvider
                        .routeVoiceController,
                    eventsManager: mapboxNavigationProvider.eventsManager(),
                    // Passing styles with the rest of the options.
                    styles: [CustomDayStyle(), CustomNightStyle()]
                )
                let navigationViewController = NavigationViewController(
                    navigationRoutes: navigationRoutes,
                    navigationOptions: navigationOptions
                )

                navigationViewController.modalPresentationStyle = .fullScreen
                // Render part of the route that has been traversed with full transparency, to give the illusion of a
                // disappearing route.
                navigationViewController.routeLineTracksTraversal = true

                // Congestion colors are configured directly in `NavigationMapView`.
                let colors = CongestionColorsConfiguration.Colors(
                    low: .red,
                    moderate: .purple,
                    heavy: .orange,
                    severe: .yellow,
                    unknown: .gray
                )
                navigationViewController.navigationMapView?.congestionConfiguration = .init(
                    colors: .init(
                        mainRouteColors: colors,
                        alternativeRouteColors: colors
                    ),
                    ranges: .default
                )

                present(navigationViewController, animated: true, completion: nil)
            }
        }
    }
}

private final class CustomDayStyle: DayStyle {
    private let backgroundColor = #colorLiteral(red: 0.06276176125, green: 0.6164312959, blue: 0.3432356119, alpha: 1)
    private let darkBackgroundColor = #colorLiteral(red: 0.0473754704, green: 0.4980872273, blue: 0.2575169504, alpha: 1)
    private let secondaryBackgroundColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
    private let blueColor = #colorLiteral(red: 0.26683864, green: 0.5903761983, blue: 1, alpha: 1)
    private let lightGrayColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
    private let darkGrayColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    private let primaryLabelColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    private let secondaryLabelColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.9)

    required init() {
        super.init()
        mapStyleURL = URL(string: "mapbox://styles/mapbox/satellite-streets-v9")!
        styleType = .day
    }

    override func apply() {
        super.apply()

        let traitCollection = UIScreen.main.traitCollection
        ArrivalTimeLabel.appearance(for: traitCollection).textColor = lightGrayColor
        BottomBannerView.appearance(for: traitCollection).backgroundColor = secondaryBackgroundColor
        BottomPaddingView.appearance(for: traitCollection).backgroundColor = secondaryBackgroundColor
        Button.appearance(for: traitCollection).textColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        CancelButton.appearance(for: traitCollection).tintColor = lightGrayColor
        DistanceLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self])
            .unitTextColor = secondaryLabelColor
        DistanceLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self])
            .valueTextColor = primaryLabelColor
        DistanceLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [StepInstructionsView.self])
            .unitTextColor = lightGrayColor
        DistanceLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [StepInstructionsView.self])
            .valueTextColor = darkGrayColor
        DistanceRemainingLabel.appearance(for: traitCollection).textColor = lightGrayColor
        DismissButton.appearance(for: traitCollection).textColor = darkGrayColor
        FloatingButton.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
        FloatingButton.appearance(for: traitCollection).tintColor = blueColor
        TopBannerView.appearance(for: traitCollection).backgroundColor = backgroundColor
        InstructionsBannerView.appearance(for: traitCollection).backgroundColor = backgroundColor
        LanesView.appearance(for: traitCollection).backgroundColor = darkBackgroundColor
        LaneView.appearance(for: traitCollection).primaryColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        ManeuverView.appearance(for: traitCollection).backgroundColor = backgroundColor
        ManeuverView.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self])
            .primaryColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        ManeuverView.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self])
            .secondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5)
        ManeuverView.appearance(for: traitCollection, whenContainedInInstancesOf: [NextBannerView.self])
            .primaryColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        ManeuverView.appearance(for: traitCollection, whenContainedInInstancesOf: [NextBannerView.self])
            .secondaryColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.5)
        ManeuverView.appearance(for: traitCollection, whenContainedInInstancesOf: [StepInstructionsView.self])
            .primaryColor = darkGrayColor
        ManeuverView.appearance(for: traitCollection, whenContainedInInstancesOf: [StepInstructionsView.self])
            .secondaryColor = lightGrayColor
        NextBannerView.appearance(for: traitCollection).backgroundColor = backgroundColor
        NextInstructionLabel.appearance(for: traitCollection).textColor = #colorLiteral(red: 0.9842069745, green: 0.9843751788, blue: 0.9841964841, alpha: 1)
        NavigationMapView.appearance(for: traitCollection).tintColor = blueColor
        PrimaryLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self])
            .normalTextColor = primaryLabelColor
        PrimaryLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [StepInstructionsView.self])
            .normalTextColor = darkGrayColor
        ResumeButton.appearance(for: traitCollection).backgroundColor = secondaryBackgroundColor
        ResumeButton.appearance(for: traitCollection).tintColor = blueColor
        SecondaryLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [InstructionsBannerView.self])
            .normalTextColor = secondaryLabelColor
        SecondaryLabel.appearance(for: traitCollection, whenContainedInInstancesOf: [StepInstructionsView.self])
            .normalTextColor = darkGrayColor
        TimeRemainingLabel.appearance(for: traitCollection).textColor = lightGrayColor
        TimeRemainingLabel.appearance(for: traitCollection).trafficLowColor = darkBackgroundColor
        TimeRemainingLabel.appearance(for: traitCollection).trafficUnknownColor = darkGrayColor
        WayNameLabel.appearance(for: traitCollection).normalTextColor = blueColor
        WayNameView.appearance(for: traitCollection).backgroundColor = secondaryBackgroundColor
    }
}

private final class CustomNightStyle: NightStyle {
    private let backgroundColor = #colorLiteral(red: 0.06276176125, green: 0.6164312959, blue: 0.3432356119, alpha: 1)
    private let darkBackgroundColor = #colorLiteral(red: 0.0473754704, green: 0.4980872273, blue: 0.2575169504, alpha: 1)
    private let secondaryBackgroundColor = #colorLiteral(red: 0.1335069537, green: 0.133641988, blue: 0.1335278749, alpha: 1)
    private let blueColor = #colorLiteral(red: 0.26683864, green: 0.5903761983, blue: 1, alpha: 1)
    private let lightGrayColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
    private let darkGrayColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    private let primaryTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    private let secondaryTextColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 0.9)

    required init() {
        super.init()
        mapStyleURL = URL(string: "mapbox://styles/mapbox/satellite-streets-v9")!
        styleType = .night
    }

    override func apply() {
        super.apply()

        let traitCollection = UIScreen.main.traitCollection
        DistanceRemainingLabel.appearance(for: traitCollection).normalTextColor = primaryTextColor
        BottomBannerView.appearance(for: traitCollection).backgroundColor = secondaryBackgroundColor
        BottomPaddingView.appearance(for: traitCollection).backgroundColor = secondaryBackgroundColor
        FloatingButton.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 0.1434620917, green: 0.1434366405, blue: 0.1819391251, alpha: 0.9037466989)
        TimeRemainingLabel.appearance(for: traitCollection).textColor = primaryTextColor
        TimeRemainingLabel.appearance(for: traitCollection).trafficLowColor = primaryTextColor
        TimeRemainingLabel.appearance(for: traitCollection).trafficUnknownColor = primaryTextColor
        ResumeButton.appearance(for: traitCollection).backgroundColor = #colorLiteral(red: 0.1434620917, green: 0.1434366405, blue: 0.1819391251, alpha: 0.9037466989)
        ResumeButton.appearance(for: traitCollection).tintColor = blueColor
    }
}
