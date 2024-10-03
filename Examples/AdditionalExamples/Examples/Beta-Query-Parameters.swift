/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios
 To learn more about the SDK, see our docs: https://docs.mapbox.com/ios/navigation
 */

import MapboxDirections
import MapboxMaps
import MapboxNavigationCore
import MapboxNavigationUIKit
import UIKit

final class BetaQueryViewController: UIViewController {
    private let mapboxNavigationProvider = MapboxNavigationProvider(
        coreConfig: .init(
            locationSource: simulationIsEnabled ? .simulation(
                initialLocation: nil
            ) : .live
        )
    )
    private var mapboxNavigation: MapboxNavigation {
        mapboxNavigationProvider.mapboxNavigation
    }

    private var navigationMapView: NavigationMapView!

    private var navigationRoutes: NavigationRoutes? {
        didSet {
            guard let navigationRoutes else {
                navigationMapView.removeRoutes()
                return
            }
            navigationMapView.showcase(navigationRoutes)
        }
    }

    private var startButton: UIButton!
    private var datePicker: UIDatePicker!
    private var dateTextField: UITextField!
    private var departureTime: Date!

    // MARK: - UIViewController lifecycle methods

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationMapView = .init(
            location: mapboxNavigation.navigation()
                .locationMatching.map(\.enhancedLocation)
                .eraseToAnyPublisher(),
            routeProgress: mapboxNavigation.navigation()
                .routeProgress.map(\.?.routeProgress)
                .eraseToAnyPublisher(),
            predictiveCacheManager: mapboxNavigationProvider.predictiveCacheManager
        )
        navigationMapView.translatesAutoresizingMaskIntoConstraints = false
        navigationMapView.delegate = self

        view.addSubview(navigationMapView)

        NSLayoutConstraint.activate([
            navigationMapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationMapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationMapView.topAnchor.constraint(equalTo: view.topAnchor),
            navigationMapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        startButton = UIButton()
        startButton.setTitle("Start Navigation", for: .normal)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.backgroundColor = .blue
        startButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        startButton.addTarget(self, action: #selector(tappedStartButton(sender:)), for: .touchUpInside)
        startButton.isHidden = true
        view.addSubview(startButton)

        startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
            .isActive = true
        startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        view.setNeedsLayout()

        setupDateProperties()

        mapboxNavigation.tripSession().startFreeDrive()
    }

    // Override layout lifecycle callback to be able to style the start button.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        startButton.layer.cornerRadius = startButton.bounds.midY
        startButton.clipsToBounds = true
        startButton.setNeedsDisplay()
    }

    private func setupDateProperties() {
        dateTextField = UITextField(frame: CGRect(x: 75, y: 100, width: 200, height: 35))
        dateTextField.placeholder = "Select departure time"
        dateTextField.backgroundColor = UIColor.white
        dateTextField.borderStyle = .roundedRect
        dateTextField.center.x = view.center.x
        dateTextField.isHidden = false
        showDatePicker()
        view.addSubview(dateTextField)
    }

    private func showDatePicker() {
        datePicker = UIDatePicker()
        datePicker.datePickerMode = .time
        datePicker.preferredDatePickerStyle = .wheels
        datePicker.minimumDate = Date()

        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: nil, action: #selector(doneButtonPressed))
        toolbar.setItems([doneButton], animated: true)

        dateTextField?.inputAccessoryView = toolbar
        dateTextField?.inputView = datePicker
    }

    @objc
    private func doneButtonPressed() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm" // format date correctly
        dateTextField.text = dateFormatter.string(from: datePicker.date)
        view.endEditing(true)
    }

    @objc
    private func tappedStartButton(sender: UIButton) {
        guard let navigationRoutes else { return }

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

        present(navigationViewController, animated: true, completion: nil)
    }

    private func requestRoute(destination: CLLocationCoordinate2D) {
        guard let userLocation = navigationMapView.mapView.location.latestLocation else { return }

        let location = CLLocation(
            latitude: userLocation.coordinate.latitude,
            longitude: userLocation.coordinate.longitude
        )

        let userWaypoint = Waypoint(
            location: location,
            name: "user"
        )

        let destinationWaypoint = Waypoint(coordinate: destination)
        let navigationRouteOptions = MopedRouteOptions(
            waypoints: [userWaypoint, destinationWaypoint],
            departTime: dateTextField.text!
        )

        let request = mapboxNavigation.routingProvider().calculateRoutes(options: navigationRouteOptions)

        Task {
            switch await request.result {
            case .failure(let error):
                print(error.localizedDescription)
            case .success(let response):
                self.navigationRoutes = response
                self.startButton?.isHidden = false
                self.dateTextField?.isHidden = true
            }
        }
    }
}

extension BetaQueryViewController: NavigationViewControllerDelegate {
    func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    ) {
        dismiss(animated: true, completion: nil)
    }
}

extension BetaQueryViewController: NavigationMapViewDelegate {
    func navigationMapView(_ navigationMapView: NavigationMapView, userDidLongTap mapPoint: MapPoint) {
        guard dateTextField?.text != nil else { return }
        requestRoute(destination: mapPoint.coordinate)
    }
}

final class MopedRouteOptions: NavigationRouteOptions, @unchecked Sendable {
    var departureTime: String!

    // add departureTime to URLQueryItems
    override var urlQueryItems: [URLQueryItem] {
        var items = super.urlQueryItems
        items.append(URLQueryItem(name: "depart_at", value: departureTime))
        return items
    }

    // create initializer to take in the departure time
    public init(waypoints: [Waypoint], departTime: String) {
        self.departureTime = departTime
        super.init(waypoints: waypoints)
    }

    required init(from decoder: Decoder) throws {
        fatalError("init(from:) has not been implemented")
    }

    required init(waypoints: [Waypoint], profileIdentifier: ProfileIdentifier? = .automobileAvoidingTraffic) {
        fatalError("init(waypoints:profileIdentifier:) has not been implemented")
    }

    required init(
        waypoints: [Waypoint],
        profileIdentifier: ProfileIdentifier? = .automobileAvoidingTraffic,
        queryItems: [URLQueryItem]? = nil
    ) {
        fatalError("init(waypoints:profileIdentifier:queryItems:) has not been implemented")
    }
}
