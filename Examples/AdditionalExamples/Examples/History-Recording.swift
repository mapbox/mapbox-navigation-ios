/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios-examples
 To learn more about each example in this app, including descriptions and links
 to documentation, see our docs: https://docs.mapbox.com/ios/navigation/examples
 */

import UIKit
import MapboxNavigationUIKit
import MapboxNavigationCore
import MapboxDirections
import MapboxMaps

func defaultHistoryDirectoryURL() -> URL {
    let basePath: String
    if let applicationSupportPath =
        NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true).first {
        basePath = applicationSupportPath
    } else {
        basePath = NSTemporaryDirectory()
    }
    let historyDirectoryURL = URL(fileURLWithPath: basePath, isDirectory: true)
        .appendingPathComponent("com.mapbox.Example")
        .appendingPathComponent("NavigationHistory")
    
    if FileManager.default.fileExists(atPath: historyDirectoryURL.path) == false {
        try? FileManager.default.createDirectory(at: historyDirectoryURL,
                                                 withIntermediateDirectories: true,
                                                 attributes: nil)
    }
    return historyDirectoryURL
}

class HistoryRecordingViewController: UIViewController, NavigationMapViewDelegate, NavigationViewControllerDelegate {
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
    
    let mapboxNavigationProvider = MapboxNavigationProvider(
        coreConfig: .init(
            locationSource: simulationIsEnabled ? .simulation(
                initialLocation: nil
            ) : .live,
            // setting up the custom history repository location.
            // If not set, the default directory will be used.
            historyRecordingConfig: HistoryRecordingConfig(historyDirectoryURL: defaultHistoryDirectoryURL())
        )
    )
    lazy var mapboxNavigation = mapboxNavigationProvider.mapboxNavigation

    var navigationRoutes: NavigationRoutes? {
        didSet {
            showCurrentRoute()
        }
    }
    
    func showCurrentRoute() {
        guard let navigationRoutes else {
            navigationMapView.removeRoutes()
            return
        }
        navigationMapView.showcase(navigationRoutes)
    }
    
    var startButton: UIButton!
    
    func loadNavigationViewIfNeeded() {
        if navigationMapView == nil {
            navigationMapView = .init(
                location: mapboxNavigation.navigation().locationMatching.map(\.location).eraseToAnyPublisher(),
                routeProgress: mapboxNavigation.navigation().routeProgress.map(\.?.routeProgress).eraseToAnyPublisher(),
                predictiveCacheManager: mapboxNavigationProvider.predictiveCacheManager
            )
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadNavigationViewIfNeeded()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        mapboxNavigation.historyRecorder()?.startRecordingHistory()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        mapboxNavigation.historyRecorder()?.stopRecordingHistory { historyFileUrl in
            guard let historyFileUrl = historyFileUrl else { return }
            print("Free Drive History file has been successfully saved at the path: \(historyFileUrl.path)")
        }
    }
    
    private func configure() {
        setupNavigationMapView()
        startFreeDrive()
        
        // set start button
        startButton = UIButton()
        startButton.setTitle("Start Navigation", for: .normal)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.backgroundColor = .blue
        startButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        startButton.addTarget(self, action: #selector(tappedButton(sender:)), for: .touchUpInside)
        startButton.isHidden = true
        view.addSubview(startButton)
        startButton.bottomAnchor.constraint(equalTo: self.view.safeAreaLayoutGuide.bottomAnchor, constant: -20).isActive = true
        startButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
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
            navigationMapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

    }
    
    func requestRoute(destination: CLLocationCoordinate2D) {
        guard let userLocation = navigationMapView.mapView.location.latestLocation else { return }
        let location = CLLocation(latitude: userLocation.coordinate.latitude,
                                  longitude: userLocation.coordinate.longitude)
        
        let userWaypoint = Waypoint(location: location,
                                    name: "user")
        
        let destinationWaypoint = Waypoint(coordinate: destination)
        
        let navigationRouteOptions = NavigationRouteOptions(waypoints: [userWaypoint, destinationWaypoint])
        
        Task {
            switch await mapboxNavigation.routingProvider().calculateRoutes(options: navigationRouteOptions).result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                self.navigationRoutes = response
                self.startButton?.isHidden = false
            }
        }
    }
    
    // Override layout lifecycle callback to be able to style the start button.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        startButton.layer.cornerRadius = startButton.bounds.midY
        startButton.clipsToBounds = true
        startButton.setNeedsDisplay()
    }
    
    @objc func tappedButton(sender: UIButton) {
        guard let navigationRoutes else { return }
        
        let navigationOptions = NavigationOptions(
            mapboxNavigation: mapboxNavigation,
            voiceController: mapboxNavigationProvider.routeVoiceController,
            eventsManager: mapboxNavigationProvider.eventsManager()
        )
        let navigationViewController = NavigationViewController(navigationRoutes: navigationRoutes,
                                                                navigationOptions: navigationOptions)
        navigationViewController.delegate = self
        navigationViewController.modalPresentationStyle = .fullScreen
        navigationViewController.routeLineTracksTraversal = true
        
        presentAndRemoveNaviagationMapView(navigationViewController)
    }
    
    func navigationViewControllerDidDismiss(_ navigationViewController: NavigationViewController, byCanceling canceled: Bool) {
        mapboxNavigation.historyRecorder()?.stopRecordingHistory { historyFileUrl in
            guard let historyFileUrl = historyFileUrl else { return }
            print("Active Guidance History file has been successfully saved at the path: \(historyFileUrl.path)")
        }
        dismiss(animated: true, completion: nil)
        loadNavigationViewIfNeeded()
    }
    
    func presentAndRemoveNaviagationMapView(_ navigationViewController: NavigationViewController,
                                            animated: Bool = true,
                                            completion: CompletionHandler? = nil) {

        navigationViewController.modalPresentationStyle = .fullScreen
        present(navigationViewController, animated: animated) {
            completion?()
            self.navigationMapView = nil

            self.mapboxNavigation.historyRecorder()?.startRecordingHistory()
        }
    }
    
    // MARK: NavigationMapViewDelegate implementation
    
    func navigationMapView(_ navigationMapView: NavigationMapView, userDidLongTap mapPoint: MapPoint) {
        requestRoute(destination: mapPoint.coordinate)
    }
    
    // Delegate method called when the user selects a route
    func navigationMapView(_ navigationMapView: NavigationMapView, didSelect alternativeRoute: AlternativeRoute) {
        Task {
            guard let selectedRoutes = await self.navigationRoutes?.selecting(alternativeRoute: alternativeRoute) else { return }
            self.navigationRoutes = selectedRoutes
        }
    }
}
