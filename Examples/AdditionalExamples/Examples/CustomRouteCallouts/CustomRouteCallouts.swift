/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios
 To learn more about the SDK, see our docs: https://docs.mapbox.com/ios/navigation
 */

import Combine
import CoreLocation

// Route callouts customization API is currently experimental thus import of MapboxNavigationCore
// with @_spi(ExperimentalMapboxAPI) is required to obtain access to it.
@_spi(ExperimentalMapboxAPI) import MapboxNavigationCore
import MapboxNavigationUIKit
import UIKit

final class CustomRouteCalloutsViewController: UIViewController {
    private func setupNavigationMapView() {
        navigationMapView = .init(
            location: mapboxNavigation.navigation().locationMatching.map(\.enhancedLocation)
                .eraseToAnyPublisher(),
            routeProgress: mapboxNavigation.navigation().routeProgress.map(\.?.routeProgress).eraseToAnyPublisher()
        )

        // Experimental API needs to be enabled, so that custom route callout
        // view provider is taken into account in callouts rendering
        navigationMapView.apiRouteCalloutViewProviderEnabled = true
        calloutViewProvider = CustomRouteCalloutViewProvider()
        navigationMapView.routeCalloutViewProvider = calloutViewProvider
    }

    private func setupSessionSubscription() {
        // The below code demostrated how to change style of route callouts dynamically
        // based on current navigation state (represented by MapboxNavigationCore.Session).
        mapboxNavigation.tripSession().session
            .receive(on: DispatchQueue.main)
            .sink { [weak self] session in
                guard let self else { return }
                switch session.state {
                case .idle, .freeDrive:
                    calloutViewProvider.presentationStyle = .routePreview
                    segmentedControl.selectedSegmentIndex = 0
                    segmentedControl.isHidden = navigationRoutes != .none
                case .activeGuidance:
                    calloutViewProvider.presentationStyle = .activeGuidance
                    segmentedControl.selectedSegmentIndex = 1
                    segmentedControl.isHidden = true
                }
            }
            .store(in: &cancellables)
    }

    private func setupControls() {
        segmentedControl = UISegmentedControl(items: ["Route preview style", "Active guidance style"])
        segmentedControl.selectedSegmentIndex = 0
        let textAttributes = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .semibold)]
        segmentedControl.setTitleTextAttributes(textAttributes, for: .normal)
        segmentedControl.setTitleTextAttributes(textAttributes, for: .selected)

        let setRoutePreviewStyleAction = UIAction(title: "Route preview style") { [weak self] _ in
            guard let self else { return }
            calloutViewProvider.presentationStyle = .routePreview
        }
        let setActiveGuidanceStyleAction = UIAction(title: "Active guidance style") { [weak self] _ in
            guard let self else { return }
            calloutViewProvider.presentationStyle = .activeGuidance
        }

        segmentedControl.setAction(setRoutePreviewStyleAction, forSegmentAt: 0)
        segmentedControl.setAction(setActiveGuidanceStyleAction, forSegmentAt: 1)
        segmentedControl.isHidden = true

        startButton = UIButton()
        startButton.isHidden = true
        startButton.setTitle("Start navigation", for: .normal)
        startButton.addTarget(self, action: #selector(startNavigation), for: .touchUpInside)
    }

    @objc
    private func startNavigation() {
        guard let navigationRoutes else { return }

        let navigationOptions = NavigationOptions(
            mapboxNavigation: mapboxNavigation,
            voiceController: mapboxNavigationProvider.routeVoiceController,
            eventsManager: mapboxNavigationProvider.eventsManager(),
            styles: [StandardDayStyle(), StandardNightStyle()],
            predictiveCacheManager: mapboxNavigationProvider.predictiveCacheManager,
            // Replace default `NavigationMapView` instance with instance that is used in preview mode.
            navigationMapView: navigationMapView
        )

        let navigationViewController = NavigationViewController(
            navigationRoutes: navigationRoutes,
            navigationOptions: navigationOptions
        )
        // Enables the dark/light appearance switch.
        navigationViewController.usesNightStyleInDarkMode = true
        navigationViewController.delegate = self
        navigationViewController.modalPresentationStyle = .fullScreen

        startButton.isHidden = true

        // Hide top and bottom container views before animating their presentation.
        navigationViewController.navigationView.bottomBannerContainerView.hide(animated: false)
        navigationViewController.navigationView.topBannerContainerView.hide(animated: false)

        // Hide `WayNameView`, `FloatingStackView` and `SpeedLimitView` to smoothly present them.
        navigationViewController.navigationView.wayNameView.alpha = 0.0
        navigationViewController.navigationView.floatingStackView.alpha = 0.0
        navigationViewController.navigationView.speedLimitView.alpha = 0.0

        present(navigationViewController, animated: false) {
            // Animate top and bottom banner views presentation.
            let duration = 1.0
            navigationViewController.navigationView.bottomBannerContainerView.show(
                duration: duration,
                animations: {
                    navigationViewController.navigationView.wayNameView.alpha = 1.0
                    navigationViewController.navigationView.floatingStackView.alpha = 1.0
                    navigationViewController.navigationView.speedLimitView.alpha = 1.0
                }
            )
            navigationViewController.navigationView.topBannerContainerView.show(duration: duration)
        }
    }

    private static let coreConfig = CoreConfig(
        locationSource: .simulation(initialLocation: CustomRouteCalloutsViewController.initialLocation)
    )

    private let mapboxNavigationProvider = MapboxNavigationProvider(coreConfig: coreConfig)

    private var mapboxNavigation: MapboxNavigation {
        mapboxNavigationProvider.mapboxNavigation
    }

    private var navigationRoutes: NavigationRoutes? {
        didSet {
            switch navigationRoutes {
            case .none:
                segmentedControl.isHidden = true
            case .some:
                segmentedControl.isHidden = false
            }
        }
    }

    private var cancellables = Set<AnyCancellable>()

    private var navigationMapView: NavigationMapView! {
        didSet {
            if oldValue != nil {
                oldValue.removeFromSuperview()
            }

            navigationMapView.translatesAutoresizingMaskIntoConstraints = false
            navigationMapView.delegate = self
            // Increasing top viewport padding (compared to default) to accomodate for segmented control
            // and navigation start/stop button
            navigationMapView.viewportPadding = UIEdgeInsets(top: 50, left: 20, bottom: 90, right: 20)

            view.insertSubview(navigationMapView, at: 0)

            NSLayoutConstraint.activate([
                navigationMapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                navigationMapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                navigationMapView.topAnchor.constraint(equalTo: view.topAnchor),
                navigationMapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }
    }

    private var calloutViewProvider: CustomRouteCalloutViewProvider!

    private var segmentedControl: UISegmentedControl! {
        didSet {
            if oldValue != nil {
                oldValue.removeFromSuperview()
            }

            segmentedControl.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(segmentedControl)

            NSLayoutConstraint.activate([
                segmentedControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10.0),
                segmentedControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10.0),
                segmentedControl.heightAnchor.constraint(equalToConstant: 40.0),
            ])
        }
    }

    private var startButton: UIButton! {
        didSet {
            if oldValue != nil {
                oldValue.removeFromSuperview()
            }

            startButton.translatesAutoresizingMaskIntoConstraints = false
            startButton.backgroundColor = .blue
            startButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
            view.addSubview(startButton)

            NSLayoutConstraint.activate([
                startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            ])
        }
    }

    private static let initialCoordinate = CLLocationCoordinate2DMake(52.26914948772005, 20.999553308297116)
    private static let initialLocation = CLLocation(
        latitude: initialCoordinate.latitude,
        longitude: initialCoordinate.longitude
    )
    private static let destinationCoordinate = CLLocationCoordinate2DMake(54.352390724300434, 18.660650351531572)

    private func requestRoutes() {
        navigationMapView.removeRoutes()
        navigationRoutes = nil
        segmentedControl.selectedSegmentIndex = 0

        let origin = Self.initialCoordinate
        let destination = Self.destinationCoordinate
        let options = NavigationRouteOptions(coordinates: [origin, destination])

        let request = mapboxNavigation.routingProvider().calculateRoutes(options: options)

        Task {
            switch await request.result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let navigationRoutes):
                self.navigationRoutes = navigationRoutes
                Task { @MainActor in
                    // The below call also also renders route callouts in this example.
                    // But it will not if a custom route callout provider decides not to return views
                    // or if navigationMapView.routeCalloutViewProvider is nil.
                    navigationMapView.showcaseRoutes(navigationRoutes)
                    startButton.isHidden = false
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavigationMapView()
        setupSessionSubscription()
        setupControls()
        requestRoutes()
    }

    override func updateViewConstraints() {
        segmentedControl.topAnchor.constraint(equalTo: view.topAnchor, constant: view.safeAreaInsets.top)
            .isActive = true
        startButton.bottomAnchor.constraint(
            equalTo: view.bottomAnchor, constant: -view.safeAreaInsets.bottom - 40
        )
        .isActive = true

        super.updateViewConstraints()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        startButton.layer.cornerRadius = startButton.bounds.midY
        startButton.clipsToBounds = true
        startButton.setNeedsDisplay()
    }
}

extension CustomRouteCalloutsViewController: NavigationMapViewDelegate {
    func navigationMapView(_ navigationMapView: NavigationMapView, didSelect alternativeRoute: AlternativeRoute) {
        Task {
            guard let routesWithNewMainOne = await self.navigationRoutes?.selecting(alternativeRoute: alternativeRoute)
            else { return }
            self.navigationRoutes = routesWithNewMainOne

            Task { @MainActor in
                // The below call will also redraw callouts using new data
                // if route callout view provider is present and if it returns callout views.
                navigationMapView.showRoutes(routesWithNewMainOne)
            }
        }
    }
}

extension CustomRouteCalloutsViewController: NavigationViewControllerDelegate {
    func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    ) {
        let duration = 1.0
        navigationViewController.navigationView.topBannerContainerView.hide(duration: duration)
        navigationViewController.navigationView.bottomBannerContainerView.hide(
            duration: duration,
            animations: {
                navigationViewController.navigationView.wayNameView.alpha = 0.0
                navigationViewController.navigationView.floatingStackView.alpha = 0.0
                navigationViewController.navigationView.speedLimitView.alpha = 0.0
            },
            completion: { [weak self] _ in
                navigationViewController.dismiss(animated: false) {
                    guard let self else { return }

                    // Since `NavigationViewController` assigns `NavigationMapView`'s delegate to itself,
                    // delegate should be re-assigned back to `NavigationMapView` that is used in preview mode.
                    self.navigationMapView.delegate = self

                    // Replace `NavigationMapView` instance with instance that was used in active navigation.
                    self.navigationMapView = navigationViewController.navigationMapView

                    // Re-start Free drive
                    self.mapboxNavigation.tripSession().startFreeDrive()

                    // Reset initial simulated location by resetting config
                    self.mapboxNavigationProvider.apply(coreConfig: Self.coreConfig)

                    // Showcase originally requested routes.
                    self.requestRoutes()
                }
            }
        )
    }
}
