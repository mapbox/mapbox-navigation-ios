/*
 This code example is part of the Mapbox Navigation SDK for iOS demo app,
 which you can build and run: https://github.com/mapbox/mapbox-navigation-ios
 To learn more about the SDK, see our docs: https://docs.mapbox.com/ios/navigation
 */

import MapboxDirections
import MapboxMaps
import MapboxNavigationCore
import MapboxNavigationNative
import MapboxNavigationUIKit
import UIKit

class OfflineRegionsViewController: UIViewController {
    let mapboxNavigationProvider = MapboxNavigationProvider(
        coreConfig: .init(
            // For demonstration purposes, simulate locations if the Simulate Navigation option is on.
            locationSource: simulationIsEnabled ? .simulation(
                initialLocation: nil
            ) : .live,
            // Though not recommended, the tile store can also be configure with custom storage location.
            tilestoreConfig: .default
        )
    )
    lazy var mapboxNavigation = mapboxNavigationProvider.mapboxNavigation

    // MARK: Setup variables for Tile Management

    let styleURI: StyleURI = .streets
    var region: Region?
    let zoomMin: UInt8 = 0
    let zoomMax: UInt8 = 16
    let offlineManager = OfflineManager()
    var tileStoreConfiguration: TileStoreConfiguration {
        mapboxNavigationProvider.coreConfig.tilestoreConfig
    }

    var tileStoreLocation: TileStoreConfiguration.Location {
        tileStoreConfiguration.navigatorLocation
    }

    var tileStore: TileStore {
        tileStoreLocation.tileStore
    }

    var currentLocation: CLLocation? {
        mapboxNavigation.navigation().currentLocationMatching?.mapMatchingResult.enhancedLocation
    }

    var downloadButton = UIButton()
    var startButton = UIButton()
    var navigationMapView: NavigationMapView?
    var options: NavigationRouteOptions?

    var navigationRoutes: NavigationRoutes? {
        didSet {
            showRoutes()
            showStartNavigationAlert()
        }
    }

    struct Region {
        var bbox: [CLLocationCoordinate2D]
        var identifier: String
    }

    // MARK: Life cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigationMapView()
        addDownloadButton()
        addStartButton()
    }

    func setupNavigationMapView() {
        let navigationMapView = NavigationMapView(
            location: mapboxNavigation.navigation()
                .locationMatching.map(\.enhancedLocation)
                .eraseToAnyPublisher(),
            routeProgress: mapboxNavigation.navigation()
                .routeProgress.map(\.?.routeProgress)
                .eraseToAnyPublisher(),
            predictiveCacheManager: mapboxNavigationProvider.predictiveCacheManager
        )
        navigationMapView.delegate = self
        navigationMapView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(navigationMapView)

        NSLayoutConstraint.activate([
            navigationMapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            navigationMapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            navigationMapView.topAnchor.constraint(equalTo: view.topAnchor),
            navigationMapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        self.navigationMapView = navigationMapView

        mapboxNavigation.tripSession().startFreeDrive()
    }

    func addDownloadButton() {
        downloadButton.setTitle("Download Offline Region", for: .normal)
        downloadButton.backgroundColor = .blue
        downloadButton.layer.cornerRadius = 5
        downloadButton.translatesAutoresizingMaskIntoConstraints = false
        downloadButton.addTarget(self, action: #selector(tappedDownloadButton(sender:)), for: .touchUpInside)
        view.addSubview(downloadButton)

        downloadButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50)
            .isActive = true
        downloadButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        downloadButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        downloadButton.sizeToFit()
        downloadButton.titleLabel?.font = UIFont.systemFont(ofSize: 25)
    }

    func addStartButton() {
        startButton.setTitle("Start Offline Navigation", for: .normal)
        startButton.backgroundColor = .blue
        startButton.layer.cornerRadius = 5
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.addTarget(self, action: #selector(tappedStartButton(sender:)), for: .touchUpInside)
        showStartButton(false)
        view.addSubview(startButton)

        startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50)
            .isActive = true
        startButton.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor).isActive = true
        startButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        startButton.sizeToFit()
        startButton.titleLabel?.font = UIFont.systemFont(ofSize: 25)
    }

    func showStartButton(_ show: Bool = true) {
        startButton.isHidden = !show
        startButton.isEnabled = show
    }

    @objc
    func tappedDownloadButton(sender: UIButton) {
        downloadButton.isHidden = true
        downloadTileRegion()
    }

    @objc
    func tappedStartButton(sender: UIButton) {
        showStartButton(false)
        startNavigation()
    }

    // MARK: Offline navigation

    func showRoutes() {
        guard let navigationRoutes else { return }
        navigationMapView?.showsRestrictedAreasOnRoute = true
        navigationMapView?.showcase(navigationRoutes, routeAnnotationKinds: [.routeDurations])
    }

    func showStartNavigationAlert() {
        let alertController = UIAlertController(
            title: "Start navigation",
            message: "Turn off network access to start active navigation",
            preferredStyle: .alert
        )
        let approveAction = UIAlertAction(title: "OK", style: .default, handler: { _ in self.showStartButton() })
        alertController.addAction(approveAction)
        present(alertController, animated: true, completion: nil)
    }

    func requestRoute() {
        guard let options else { return }

        Task { [weak self] in
            guard let self else { return }
            switch await mapboxNavigation.routingProvider().calculateRoutes(options: options).result {
            case .failure(let error):
                print("Failed to request route with error: \(error.localizedDescription)")
            case .success(let response):
                navigationRoutes = response
            }
        }
    }

    func startNavigation() {
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
        navigationViewController.modalPresentationStyle = .fullScreen

        present(navigationViewController, animated: true) {
            self.navigationMapView = nil
        }
    }

    // MARK: Create regions

    func createRegion() {
        guard let location = currentLocation?.coordinate else { return }
        if region == nil {
            // Generate a rectangle based on current user location
            let distance: CLLocationDistance = 1e4
            let directions: [CLLocationDegrees] = [45, 135, 225, 315, 45]
            let coordinates = directions.map { location.coordinate(at: distance, facing: $0) }
            region = Region(bbox: coordinates, identifier: "Current location")
        }
        addRegionBoxLine()
    }

    func addRegionBoxLine() {
        guard let style = navigationMapView?.mapView.mapboxMap,
              let coordinates = region?.bbox else { return }
        do {
            let identifier = "regionBox"
            var source = GeoJSONSource(id: identifier)
            source.data = .geometry(.lineString(.init(coordinates)))
            try style.addSource(source)

            var layer = LineLayer(id: identifier, source: identifier)
            layer.lineWidth = .constant(3.0)
            layer.lineColor = .constant(.init(.red))
            try style.addPersistentLayer(layer)
        } catch {
            print("Error \(error.localizedDescription) occured while adding box for region boundary.")
        }
    }

    // MARK: Download offline Regions

    func downloadTileRegion() {
        // Create style package
        createRegion()
        guard let region,
              let stylePackLoadOptions = StylePackLoadOptions(
                  glyphsRasterizationMode: nil,
                  metadata: [:]
              )
        else {
            return
        }
        _ = offlineManager.loadStylePack(
            for: styleURI,
            loadOptions: stylePackLoadOptions,
            completion: { [weak self] result in
                guard let self else { return }
                switch result {
                case .success(let stylePack):
                    print("Style pack \(stylePack.styleURI) downloaded!")
                    download(region: region)
                case .failure(let error):
                    print("Error while downloading style pack: \(error).")
                }
            }
        )
    }

    func download(region: Region) {
        guard let loadOptions = tileRegionLoadOptions(for: region) else { return }
        // loadTileRegions returns a Cancelable that allows developers to cancel downloading a region
        _ = tileStore.loadTileRegion(forId: region.identifier, loadOptions: loadOptions, progress: { progress in
            print("\(progress.loadedResourceSize)/\(progress.completedResourceSize)")
        }, completion: { result in
            switch result {
            case .success(let region):
                print("\(region.id) downloaded!")
                self.showDownloadCompletionAlert()
            case .failure(let error):
                print("Error while downloading region: \(error)")
                self.showDownloadFailedAlert(with: error)
            }
        })
    }

    // Helper method for creating TileRegionLoadOptions that are needed to download regions
    func tileRegionLoadOptions(for region: Region) -> TileRegionLoadOptions? {
        let tilesetDescriptorOptions = TilesetDescriptorOptions(
            styleURI: styleURI,
            zoomRange: zoomMin...zoomMax,
            tilesets: [
                // for more details about tileseets, see documentation page
                // `https://docs.mapbox.com/data/tilesets/reference/`
                "mapbox://mapbox.mapbox-streets-v8",
                "mapbox://mapbox.mapbox-terrain-v2",
            ]
        )
        let mapsDescriptor = offlineManager.createTilesetDescriptor(for: tilesetDescriptorOptions)
        return TileRegionLoadOptions(
            geometry: Polygon([region.bbox]).geometry,
            descriptors: [mapsDescriptor, mapboxNavigationProvider.getLatestNavigationTilesetDescriptor()],
            metadata: nil,
            acceptExpired: true,
            networkRestriction: .none
        )
    }

    func showDownloadCompletionAlert() {
        DispatchQueue.main.async {
            let alertController = UIAlertController(
                title: "Downloading completed",
                message: "Long press location inside the box to get directions",
                preferredStyle: .alert
            )
            let approveAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(approveAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }

    func showDownloadFailedAlert(with error: Error) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(
                title: "Error while downloading region",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            let approveAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alertController.addAction(approveAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
}

extension OfflineRegionsViewController: NavigationMapViewDelegate {
    func navigationMapView(_ navigationMapView: NavigationMapView, userDidLongTap mapPoint: MapPoint) {
        guard downloadButton.isHidden == true,
              let currentCoordinate = currentLocation?.coordinate else { return }

        options = NavigationRouteOptions(coordinates: [currentCoordinate, mapPoint.coordinate])
        requestRoute()
    }

    // Delegate method called when the user selects a route
    func navigationMapView(_ navigationMapView: NavigationMapView, didSelect alternativeRoute: AlternativeRoute) {
        Task {
            guard let selectedRoutes = await self.navigationRoutes?.selecting(alternativeRoute: alternativeRoute)
            else { return }
            self.navigationRoutes = selectedRoutes
        }
    }
}

extension OfflineRegionsViewController: NavigationViewControllerDelegate {
    func navigationViewControllerDidDismiss(
        _ navigationViewController: NavigationViewController,
        byCanceling canceled: Bool
    ) {
        navigationViewController.dismiss(animated: false) {
            self.setupNavigationMapView()
            self.addStartButton()
        }
    }
}
