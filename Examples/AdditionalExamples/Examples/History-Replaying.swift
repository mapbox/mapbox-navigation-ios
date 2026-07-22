/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios
 To learn more about the SDK, see our docs: https://docs.mapbox.com/ios/navigation

 Important: History replay of map-matched routes is not supported.
 `HistoryReplayController` works with history traces recorded during Directions API
 turn-by-turn sessions. Traces from Map Matching API sessions do not produce route
 assignment events, so ``HistoryReplayDelegate/historyReplayController(_:wantsToSetRoutes:)``
 will not fire for those routes.
 */

import MapboxDirections
import MapboxMaps
import MapboxNavigationCore
import MapboxNavigationUIKit
import UIKit

final class HistoryReplayingViewController: UIViewController {
    private var navigationMapView: NavigationMapView! {
        didSet {
            if let navigationMapView = oldValue {
                navigationMapView.removeFromSuperview()
            }

            if navigationMapView != nil {
                configure()
            }
        }
    }

    private lazy var historyReplayController: HistoryReplayController = {
        // Create a ``HistoryReplayController`` instance with required history data and setup it's delegate.
        // Use a Directions API history file — map-matched route replay is not supported.
        var historyReplayController = HistoryReplayController(
            historyReader: HistoryReader(
                fileUrl: Bundle.main.url(
                    forResource: "history_replay",
                    withExtension: "gz"
                )!
            )!
        )
        historyReplayController.delegate = self
        return historyReplayController
    }()

    private lazy var mapboxNavigationProvider = MapboxNavigationProvider(
        coreConfig: .init(
            routingConfig: .init(
                rerouteConfig: .init(
                    detectsReroute: false // disabling reroute detection because we are going to set new routes manually
                    // as reported by History Replayer.
                )
            ),
            locationSource: .custom(
                // History replaying is done by simulating route traversing according to the records stored in the
                // history file.
                .historyReplayingValue(with: historyReplayController)
            )
        )
    )

    private var mapboxNavigation: MapboxNavigation {
        mapboxNavigationProvider.mapboxNavigation
    }

    private var navigationRoutes: NavigationRoutes?

    private var startButton: UIButton!

    private func loadNavigationViewIfNeeded() {
        if navigationMapView == nil {
            navigationMapView = .init(
                location: mapboxNavigation.navigation()
                    .locationMatching.map(\.enhancedLocation)
                    .eraseToAnyPublisher(),
                routeProgress: mapboxNavigation.navigation()
                    .routeProgress.map(\.?.routeProgress)
                    .eraseToAnyPublisher(),
                predictiveCacheManager: mapboxNavigationProvider.predictiveCacheManager
            )
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadNavigationViewIfNeeded()
    }

    private func configure() {
        setupNavigationMapView()

        // set start button
        startButton = UIButton()
        startButton.setTitle("Start Replay", for: .normal)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.backgroundColor = .blue
        startButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        startButton.addTarget(self, action: #selector(tappedButton(sender:)), for: .touchUpInside)
        view.addSubview(startButton)
        startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
            .isActive = true
        startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        view.setNeedsLayout()
    }

    private func startFreeDrive() {
        mapboxNavigation.tripSession().startFreeDrive()
    }

    private func setupNavigationMapView() {
        navigationMapView.translatesAutoresizingMaskIntoConstraints = false

        view.insertSubview(navigationMapView, at: 0)

        NSLayoutConstraint.activate([
            navigationMapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationMapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationMapView.topAnchor.constraint(equalTo: view.topAnchor),
            navigationMapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // Override layout lifecycle callback to be able to style the start button.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        startButton.layer.cornerRadius = startButton.bounds.midY
        startButton.clipsToBounds = true
        startButton.setNeedsDisplay()
    }

    @objc
    private func tappedButton(sender: UIButton) {
        startButton.isHidden = true
        // in this example, we are starting in free drive mode (history file usually does not contain the initial
        // route), and then starting AG.
        // If you want to replay the AG drive, you should replace this `startFreeDrive()` with presenting a
        // ``NavigationViewController`` with the initial route.
        startFreeDrive()
    }

    private func presentNavigationController(with navigationRoutes: NavigationRoutes) {
        let navigationOptions = NavigationOptions(
            mapboxNavigation: mapboxNavigation,
            voiceController: mapboxNavigationProvider.routeVoiceController,
            eventsManager: mapboxNavigationProvider.eventsManager()
        )
        let navigationViewController = NavigationViewController(
            navigationRoutes: navigationRoutes,
            navigationOptions: navigationOptions
        )
        navigationViewController.delegate = self
        navigationViewController.modalPresentationStyle = .fullScreen
        navigationViewController.routeLineTracksTraversal = true

        presentAndRemoveNaviagationMapView(navigationViewController)
    }

    private func presentAndRemoveNaviagationMapView(
        _ navigationViewController: NavigationViewController,
        animated: Bool = true,
        completion: CompletionHandler? = nil
    ) {
        navigationViewController.modalPresentationStyle = .fullScreen
        present(navigationViewController, animated: animated) {
            completion?()
            self.navigationMapView = nil
        }
    }
}

extension HistoryReplayingViewController: HistoryReplayDelegate {
    func historyReplayController(
        _: MapboxNavigationCore.HistoryReplayController,
        didReplayEvent event: any MapboxNavigationCore.HistoryEvent
    ) {
        // In this example we don't need to handle this delegate method, but it is a good place to monitor all incoming
        // events as they come.
    }

    func historyReplayController(
        _: MapboxNavigationCore.HistoryReplayController,
        wantsToSetRoutes routes: MapboxNavigationCore.NavigationRoutes
    ) {
        // This method handles cases when the history file had updated current routes set. So in order to follow the
        // replay, we should do the same.
        // Note: this is only called for Directions API route assignments. Map Matching history traces do not
        // produce route assignment events.
        if presentedViewController == nil {
            presentNavigationController(with: routes)
        } else {
            mapboxNavigation.tripSession().startActiveGuidance(
                with: routes,
                startLegIndex: 0
            )
        }
    }

    func historyReplayControllerDidFinishReplay(_: HistoryReplayController) {
        presentedViewController?.dismiss(animated: true) {
            self.loadNavigationViewIfNeeded()
            self.mapboxNavigation.tripSession().setToIdle()
        }
    }
}

extension HistoryReplayingViewController: NavigationViewControllerDelegate {
    func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    ) {
        dismiss(animated: true) {
            self.mapboxNavigation.tripSession().setToIdle()
        }
        loadNavigationViewIfNeeded()
    }
}
