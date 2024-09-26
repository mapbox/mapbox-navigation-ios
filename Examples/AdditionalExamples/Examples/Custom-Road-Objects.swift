/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios
 To learn more about the SDK, see our docs: https://docs.mapbox.com/ios/navigation
 */

import Combine
import CoreLocation
import MapboxNavigationCore
import MapboxNavigationUIKit
import Turf
import UIKit

final class CustomRoadObjectsViewController: UIViewController {
    private let initialLocation = CLLocation(latitude: 37.768223, longitude: -122.417852)
    private lazy var mapboxNavigationProvider = MapboxNavigationProvider(
        coreConfig: .init(
            locationSource: simulationIsEnabled ? .simulation(initialLocation: initialLocation) : .live,
            electronicHorizonConfig: ElectronicHorizonConfig(
                length: 500,
                expansionLevel: 0,
                branchLength: 50,
                minTimeDeltaBetweenUpdates: nil
            )
        )
    )

    private var mapboxNavigation: MapboxNavigation {
        mapboxNavigationProvider.mapboxNavigation
    }

    private var electronicHorizon: ElectronicHorizonController {
        mapboxNavigation.electronicHorizon()
    }

    private var navigationMapView: NavigationMapView!

    // The data for a user-defined road object.
    private let pointFeatureJson: String =
        "{ \"type\": \"Feature\", \"id\": \"unique-id-user-defined\", \"geometry\": { \"type\": \"Point\", \"coordinates\": [ -122.417440,37.764307] }, \"properties\": { \"lane\": 1 } }"

    override func viewDidLoad() {
        super.viewDidLoad()

        configureMapView()
        mapboxNavigation.tripSession().startFreeDrive()
        addUserDefinedRoadObject()
        electronicHorizon.startUpdatingEHorizon()
    }

    private func addUserDefinedRoadObject() {
        let matcher = electronicHorizon.roadMatching.roadObjectMatcher
        matcher.delegate = self

        let data = pointFeatureJson.data(using: .utf8)!
        let feature = try! JSONDecoder().decode(Feature.self, from: data)
        guard let identifier = feature.identifier?.string else { return }
        switch feature.geometry {
        case .point(let point):
            matcher.match(point: point.coordinates, identifier: identifier, heading: nil)
        case .lineString(let lineString):
            matcher.match(polyline: lineString, identifier: identifier)
        case .polygon(let polygon):
            matcher.match(polygon: polygon, identifier: identifier)
        case .multiPolygon(let multiPolygon):
            multiPolygon.polygons.enumerated().forEach {
                matcher.match(polygon: $0.element, identifier: "\(identifier)-\($0.offset)")
            }
        default:
            ()
        }
    }

    private func startNavigation() {
        let origin = initialLocation.coordinate
        let destination = CLLocationCoordinate2DMake(37.750441, -122.416159)
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

    private func configureMapView() {
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
        view.addSubview(navigationMapView)
        navigationMapView.pinEdgesToSuperview()
    }
}

// MARK: - TopAlertsBarViewController

private class TopAlertsBarViewController: ContainerViewController {
    var topBannerView = TopBannerView()

    private var subscriptions: [AnyCancellable] = []

    init(navigationProvider: MapboxNavigationProvider) {
        super.init(nibName: nil, bundle: nil)

        let electronicHorizon = navigationProvider.mapboxNavigation.electronicHorizon()
        subscribe(to: electronicHorizon)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func subscribe(to electronicHorizon: ElectronicHorizonController) {
        electronicHorizon.eHorizonEvents
            .compactMap { $0.event as? EHorizonStatus.Events.PositionUpdated }
            .sink { [weak self] event in
                self?.handle(event: event)
            }.store(in: &subscriptions)
    }

    private func handle(event: EHorizonStatus.Events.PositionUpdated) {
        guard let distancedRoadObject = event.distances.first else {
            topBannerView.primaryLabel.text = "No objects"
            topBannerView.distanceLabel.isHidden = true
            return
        }

        topBannerView.primaryLabel.text = distancedRoadObject.kind.displayDescription
        topBannerView.distanceLabel.isHidden = false
        topBannerView.distanceLabel.text = distancedRoadObject.distanceString
    }

    private func setupView() {
        view.addSubview(topBannerView)
        let topAlertsBannerViewConstraints: [NSLayoutConstraint] = [
            topBannerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            topBannerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            topBannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            topBannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            topBannerView.heightAnchor.constraint(greaterThanOrEqualToConstant: 100.0),
        ]
        NSLayoutConstraint.activate(topAlertsBannerViewConstraints)
    }
}

private final class TopBannerView: UIControl {
    weak var primaryLabel: PrimaryLabel!
    weak var distanceLabel: DistanceLabel!

    weak var stackView: UIStackView!

    func setupViews() {
        backgroundColor = .systemBackground
        translatesAutoresizingMaskIntoConstraints = false
        layer.cornerRadius = 25
        layer.opacity = 0.8

        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)
        self.stackView = stackView

        let primaryLabel = PrimaryLabel()
        primaryLabel.numberOfLines = 0
        primaryLabel.lineBreakMode = .byWordWrapping
        primaryLabel.font = UIFont.boldSystemFont(ofSize: 25)
        primaryLabel.textColor = .label
        stackView.addArrangedSubview(primaryLabel)
        self.primaryLabel = primaryLabel

        let distanceLabel = DistanceLabel()
        distanceLabel.adjustsFontSizeToFitWidth = true
        distanceLabel.minimumScaleFactor = 16.0 / 22.0
        distanceLabel.font = UIFont.systemFont(ofSize: 20)
        distanceLabel.textColor = .label
        stackView.addArrangedSubview(distanceLabel)
        self.distanceLabel = distanceLabel
    }

    func setupLayout() {
        let constraints = [
            stackView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 10),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
        ]
        NSLayoutConstraint.activate(constraints)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    func commonInit() {
        setupViews()
        setupLayout()
    }
}

extension CustomRoadObjectsViewController: RoadObjectMatcherDelegate {
    func roadObjectMatcher(_ matcher: RoadObjectMatcher, didMatch roadObject: RoadObject) {
        guard roadObject.isUserDefined else { return }

        let store = electronicHorizon.roadMatching.roadObjectStore
        store.delegate = self
        store.addUserDefinedRoadObject(roadObject)
    }

    func roadObjectMatcher(
        _ matcher: RoadObjectMatcher,
        didFailToMatchWith error: MapboxNavigationCore.RoadObjectMatcherError
    ) {}

    func roadObjectMatcher(_ matcher: RoadObjectMatcher, didCancelMatchingFor id: String) {}
}

extension CustomRoadObjectsViewController: RoadObjectStoreDelegate {
    func didAddRoadObject(identifier: RoadObject.Identifier) {
        guard identifier == "unique-id-user-defined" else { return }

        startNavigation()
    }

    func didUpdateRoadObject(identifier: RoadObject.Identifier) {}

    func didRemoveRoadObject(identifier: RoadObject.Identifier) {}
}
