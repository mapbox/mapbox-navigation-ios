import MapboxDirections
import MapboxMaps
import MapboxNavigationCore
import MapboxNavigationUIKit
import UIKit

class HistoryReplayingViewController: UIViewController, NavigationMapViewDelegate, NavigationViewControllerDelegate {
    var navigationMapView: NavigationMapView! {
        didSet {
            if let navigationMapView = oldValue {
                navigationMapView.removeFromSuperview()
            }

            if navigationMapView != nil {
                configure()
            }
        }
    }

    lazy var historyReplayController: HistoryReplayController = {
        // Create a ``HistoryReplayController`` instance with required history data and setup it's delegate.
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

    lazy var mapboxNavigationProvider = MapboxNavigationProvider(
        coreConfig: .init(
            routingConfig: .init(
                rerouteSettings: .init(
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

    lazy var mapboxNavigation = mapboxNavigationProvider.mapboxNavigation

    var navigationRoutes: NavigationRoutes?

    var startButton: UIButton!

    func loadNavigationViewIfNeeded() {
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
        navigationMapView.delegate = self
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
    func tappedButton(sender: UIButton) {
        startButton.isHidden = true
        // in this example, we are starting in free drive mode (history file usually does not contain the initial
        // route), and then starting AG.
        // If you want to replay the AG drive, you should replace this `startFreeDrive()` with presenting a
        // ``NavigationViewController`` with the initial route.
        startFreeDrive()
    }

    func presentNavigationController(with navigationRoutes: NavigationRoutes) {
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

    func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    ) {
        dismiss(animated: true) {
            self.mapboxNavigation.tripSession().setToIdle()
        }
        loadNavigationViewIfNeeded()
    }

    func presentAndRemoveNaviagationMapView(
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
