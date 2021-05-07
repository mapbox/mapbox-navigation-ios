import UIKit
import Turf
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation
import MapboxCoreMaps
import MapboxMaps

// MARK: - Free-driving methods

extension ViewController {
    
    func setupPassiveLocationManager() {
        setupFreeDriveStyledFeatures()

        let passiveLocationDataSource = PassiveLocationDataSource()
        let passiveLocationManager = PassiveLocationManager(dataSource: passiveLocationDataSource)
        navigationMapView.mapView.location.overrideLocationProvider(with: passiveLocationManager)
        
        subscribeForFreeDriveNotifications()
    }
    
    func subscribeForFreeDriveNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didUpdatePassiveLocation),
                                               name: .passiveLocationDataSourceDidUpdate,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didUpdateElectronicHorizonPosition),
                                               name: .electronicHorizonDidUpdatePosition,
                                               object: nil)
    }
    
    func unsubscribeFromFreeDriveNotifications() {
        NotificationCenter.default.removeObserver(self, name: .passiveLocationDataSourceDidUpdate, object: nil)
        NotificationCenter.default.removeObserver(self, name: .electronicHorizonDidUpdatePosition, object: nil)
    }
    
    @objc func didUpdatePassiveLocation(_ notification: Notification) {
        if let roadName = notification.userInfo?[PassiveLocationDataSource.NotificationUserInfoKey.roadNameKey] as? String {
            title = roadName
        }
        
        if let location = notification.userInfo?[PassiveLocationDataSource.NotificationUserInfoKey.locationKey] as? CLLocation {
            trackStyledFeature.lineString.coordinates.append(contentsOf: [location.coordinate])
        }
        
        if let rawLocation = notification.userInfo?[PassiveLocationDataSource.NotificationUserInfoKey.rawLocationKey] as? CLLocation {
            rawTrackStyledFeature.lineString.coordinates.append(contentsOf: [rawLocation.coordinate])
        }
        
        speedLimitView.signStandard = notification.userInfo?[PassiveLocationDataSource.NotificationUserInfoKey.signStandardKey] as? SignStandard
        speedLimitView.speedLimit = notification.userInfo?[PassiveLocationDataSource.NotificationUserInfoKey.speedLimitKey] as? Measurement<UnitSpeed>
        
        updateFreeDriveStyledFeatures()
    }
    
    func setupFreeDriveStyledFeatures() {
        trackStyledFeature = StyledFeature(sourceIdentifier: "trackSourceIdentifier",
                                           layerIdentifier: "trackLayerIdentifier",
                                           color: .darkGray,
                                           lineWidth: 3.0,
                                           lineString: LineString([]))
        
        rawTrackStyledFeature = StyledFeature(sourceIdentifier: "rawTrackSourceIdentifier",
                                              layerIdentifier: "rawTrackLayerIdentifier",
                                              color: .lightGray,
                                              lineWidth: 3.0,
                                              lineString: LineString([]))
        
        navigationMapView.mapView.on(.styleLoaded, handler: { [weak self] _ in
            guard let self = self else { return }
            self.addStyledFeature(self.trackStyledFeature)
            self.addStyledFeature(self.rawTrackStyledFeature)
        })
    }
    
    func updateFreeDriveStyledFeatures() {
        try? navigationMapView.mapView.style.updateGeoJSONSource(withId: trackStyledFeature.sourceIdentifier,
                                                                 geoJSON: Feature(geometry: .lineString(trackStyledFeature.lineString)))
        
        try? navigationMapView.mapView.style.updateGeoJSONSource(withId: rawTrackStyledFeature.sourceIdentifier,
                                                                 geoJSON: Feature(geometry: .lineString(rawTrackStyledFeature.lineString)))
    }
    
    func addStyledFeature(_ styledFeature: StyledFeature) {
        var source = GeoJSONSource()
        source.data = .geometry(.lineString(styledFeature.lineString))
        try? navigationMapView.mapView.style.addSource(source,
                                                       id: styledFeature.sourceIdentifier)
        
        var layer = LineLayer(id: styledFeature.layerIdentifier)
        layer.source = styledFeature.sourceIdentifier
        layer.paint?.lineWidth = .constant(styledFeature.lineWidth)
        layer.paint?.lineColor = .constant(.init(color: styledFeature.color))
        try? navigationMapView.mapView.style.addLayer(layer)
    }
    
    @objc func didUpdateElectronicHorizonPosition(_ notification: Notification) {
        guard let startingEdge = notification.userInfo?[RoadGraph.NotificationUserInfoKey.treeKey] as? RoadGraph.Edge else {
            return
        }
        
        // Avoid repeating edges that have already been printed out.
        guard currentEdgeIdentifier != startingEdge.identifier ||
                nextEdgeIdentifier != startingEdge.outletEdges.first?.identifier else {
            return
        }
        currentEdgeIdentifier = startingEdge.identifier
        nextEdgeIdentifier = startingEdge.outletEdges.first?.identifier
        guard let currentEdgeIdentifier = currentEdgeIdentifier,
              let nextEdgeIdentifier = nextEdgeIdentifier else {
            return
        }
        
        // Print the current road and upcoming road.
        var statusString = "Currently on \(edgeNames(identifier: currentEdgeIdentifier).joined(separator: " / ")), approaching \(edgeNames(identifier: nextEdgeIdentifier).joined(separator: " / "))"
        
        // If there is an upcoming intersection, include the names of the cross streets.
        let branchEdgeIdentifiers = startingEdge.outletEdges.suffix(from: 1).map({ $0.identifier })
        if !branchEdgeIdentifiers.isEmpty {
            let branchNames = branchEdgeIdentifiers.flatMap { edgeNames(identifier: $0) }
            statusString += " at \(branchNames.joined(separator: ", "))"
        }
    }
    
    func edgeNames(identifier: RoadGraph.Edge.Identifier) -> [String] {
        let passiveLocationDataSource = (navigationMapView.mapView.location.locationProvider as! PassiveLocationManager).dataSource
        guard let metadata = passiveLocationDataSource.roadGraph.edgeMetadata(edgeIdentifier: identifier) else {
            return []
        }
        let names = metadata.names.map { name -> String in
            switch name {
            case .name(let name):
                return name
            case .code(let code):
                return "(\(code))"
            }
        }
        
        // If the road is unnamed, fall back to the road class.
        if names.isEmpty {
            return ["\(metadata.mapboxStreetsRoadClass.rawValue)"]
        }
        return names
    }
}
