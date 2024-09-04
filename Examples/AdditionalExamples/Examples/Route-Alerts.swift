/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios
 To learn more about the SDK, see our docs: https://docs.mapbox.com/ios/navigation
 */

import Combine
import CoreLocation
import MapboxDirections
import MapboxNavigationCore
import MapboxNavigationUIKit
import UIKit

class RouteAlertsViewController: UIViewController {
    let mapboxNavigationProvider = MapboxNavigationProvider(
        coreConfig: .init(
            locationSource: simulationIsEnabled ? .simulation(
                initialLocation: .init(
                    latitude: 37.789811651648456,
                    longitude: -122.47075850058
                )
            ) : .live
        )
    )
    lazy var mapboxNavigation = mapboxNavigationProvider.mapboxNavigation

    override func viewDidLoad() {
        super.viewDidLoad()

        let origin = CLLocationCoordinate2DMake(37.789811651648456, -122.47075850058)
        let destination = CLLocationCoordinate2DMake(37.79727245401114, -122.46951395567203)
        let options = NavigationRouteOptions(coordinates: [origin, destination])

        let request = mapboxNavigation.routingProvider().calculateRoutes(options: options)

        Task {
            switch await request.result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let navigationRoutes):
                let topAlertsBannerViewController =
                    TopAlertsBarViewController(navigationProvider: mapboxNavigationProvider)
                let navigationOptions = NavigationOptions(
                    mapboxNavigation: mapboxNavigation,
                    voiceController: mapboxNavigationProvider.routeVoiceController,
                    eventsManager: mapboxNavigationProvider.eventsManager(),
                    topBanner: topAlertsBannerViewController
                )
                let navigationViewController = NavigationViewController(
                    navigationRoutes: navigationRoutes,
                    navigationOptions: navigationOptions
                )
                navigationViewController.modalPresentationStyle = .fullScreen
                present(navigationViewController, animated: true, completion: nil)
            }
        }
    }
}

// MARK: - TopAlertsBarViewController

class TopAlertsBarViewController: ContainerViewController {
    lazy var topAlertsBannerView: InstructionsBannerView = {
        let banner = InstructionsBannerView()
        banner.translatesAutoresizingMaskIntoConstraints = false
        banner.layer.cornerRadius = 25
        banner.layer.opacity = 0.8
        return banner
    }()

    private var subscriptions: [AnyCancellable] = []

    init(navigationProvider: MapboxNavigationProvider) {
        super.init(nibName: nil, bundle: nil)

        let navigation = navigationProvider.mapboxNavigation.navigation()
        subscrite(to: navigation)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func subscrite(to navigation: NavigationController) {
        navigation.routeProgress
            .sink { [weak self] status in
                self?.update(with: status?.routeProgress)
            }
            .store(in: &subscriptions)

        navigation.bannerInstructions
            .removeDuplicates()
            .sink { [weak self] state in
                self?.topAlertsBannerView.update(for: state.visualInstruction)
            }
            .store(in: &subscriptions)

        navigation.rerouting
            .filter { $0.event is ReroutingStatus.Events.Fetched }
            .sink { [weak self] _ in
                guard let progress = navigation.currentRouteProgress?.routeProgress else { return }
                self?.topAlertsBannerView.updateDistance(for: progress.currentLegProgress.currentStepProgress)
            }
            .store(in: &subscriptions)
    }

    private func update(with routeProgress: RouteProgress?) {
        guard let routeProgress else { return }

        topAlertsBannerView.updateDistance(for: routeProgress.currentLegProgress.currentStepProgress)
        let allAlerts = routeProgress.upcomingRouteAlerts.compactMap { $0.displayDescription }
        if !allAlerts.isEmpty {
            updateAlerts(alerts: allAlerts)
        } else {
            // If there's no usable route alerts in the route progress, displaying `currentVisualInstruction` instead.
            let instruction = routeProgress.currentLegProgress.currentStepProgress.currentVisualInstruction
            topAlertsBannerView.primaryLabel.lineBreakMode = NSLineBreakMode.byTruncatingTail
            topAlertsBannerView.update(for: instruction)
        }
    }

    public func updateAlerts(alerts: [String]) {
        // Change the property of`primaryLabel: InstructionLabel`.
        let text = alerts.joined(separator: "\n")
        topAlertsBannerView.primaryLabel.text = text
        topAlertsBannerView.primaryLabel.numberOfLines = 0
        topAlertsBannerView.primaryLabel.lineBreakMode = NSLineBreakMode.byWordWrapping
    }

    private func setupConstraints() {
        view.addSubview(topAlertsBannerView)
        // To change top banner size and position change layout constraints directly.
        let topAlertsBannerViewConstraints: [NSLayoutConstraint] = [
            topAlertsBannerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            topAlertsBannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            topAlertsBannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 60),
            topAlertsBannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -60),
            topAlertsBannerView.heightAnchor.constraint(equalToConstant: 100.0),
        ]
        NSLayoutConstraint.activate(topAlertsBannerViewConstraints)
    }
}

// MARK: - RouteAlert to String implementation

extension MapboxDirections.Incident {
    var alertDescription: String {
        guard let kind else { return description }

        return switch (impact, lanesBlocked) {
        case (let impact?, let lanesBlocked?):
            "A \(impact) \(kind) ahead blocking \(lanesBlocked)"
        case (let impact?, nil):
            "A \(impact) \(kind) ahead"
        case (nil, let lanesBlocked?):
            "A \(kind) ahead blocking \(lanesBlocked)"
        case (nil, nil):
            "A \(kind) ahead"
        }
    }
}

extension MapboxNavigationCore.RouteAlert {
    public var displayDescription: String? {
        let distance = Int64(distanceToStart)
        guard distance > 0, distance < 500 else { return nil }

        switch roadObject.kind {
        case .incident(let incident?):
            return "\(incident.alertDescription) in \(distance)m."
        case .tunnel(let alert?):
            if let alertName = alert.name {
                return "Tunnel \(alertName) in \(distance)m."
            } else {
                return "A tunnel in \(distance)m."
            }
        case .borderCrossing(let alert?):
            return "Crossing border from \(alert.from) to \(alert.to) in \(distance)m."
        case .serviceArea(let alert?):
            switch alert.type {
            case .restArea:
                return "Rest area in \(distance)m."
            case .serviceArea:
                return "Service area in \(distance)m."
            }
        case .tollCollection(let alert?):
            switch alert.type {
            case .booth:
                return "Toll booth in \(distance)m."
            case .gantry:
                return "Toll gantry in \(distance)m."
            }
        default:
            return nil
        }
    }
}
