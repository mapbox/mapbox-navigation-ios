import UIKit
import Turf
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation
import MapboxCoreMaps
import MapboxMaps

// MARK: - Free-driving methods

extension ViewController {
    
    func setupPassiveLocationProvider() {
        setupFreeDriveStyledFeatures()

        let passiveLocationManager = PassiveLocationManager()
        self.passiveLocationManager = passiveLocationManager
        
        let passiveLocationProvider = PassiveLocationProvider(locationManager: passiveLocationManager)
        navigationMapView.mapView.location.overrideLocationProvider(with: passiveLocationProvider)
        
        subscribeForFreeDriveNotifications()
    }
    
    func subscribeForFreeDriveNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didUpdatePassiveLocation),
                                               name: .passiveLocationManagerDidUpdate,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didUpdateElectronicHorizonPosition),
                                               name: .electronicHorizonDidUpdatePosition,
                                               object: nil)
    }
    
    func unsubscribeFromFreeDriveNotifications() {
        NotificationCenter.default.removeObserver(self, name: .passiveLocationManagerDidUpdate, object: nil)
        NotificationCenter.default.removeObserver(self, name: .electronicHorizonDidUpdatePosition, object: nil)
    }
    
    @objc func didUpdatePassiveLocation(_ notification: Notification) {
        if let roadName = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.roadNameKey] as? String {
            title = roadName
        }
        
        if let location = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.locationKey] as? CLLocation {
            trackStyledFeature.lineString.coordinates.append(contentsOf: [location.coordinate])
            
            // Update user puck to the most recent location.
            navigationMapView.moveUserLocation(to: location, animated: true)
        }
        
        if let rawLocation = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.rawLocationKey] as? CLLocation {
            rawTrackStyledFeature.lineString.coordinates.append(contentsOf: [rawLocation.coordinate])
        }
        
        speedLimitView.signStandard = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.signStandardKey] as? SignStandard
        speedLimitView.speedLimit = notification.userInfo?[PassiveLocationManager.NotificationUserInfoKey.speedLimitKey] as? Measurement<UnitSpeed>
        
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
        
        navigationMapView.mapView.mapboxMap.onNext(.styleLoaded, handler: { [weak self] _ in
            guard let self = self else { return }
            self.addStyledFeature(self.trackStyledFeature)
            self.addStyledFeature(self.rawTrackStyledFeature)
        })
    }
    
    func updateFreeDriveStyledFeatures() {
        do {
            let style = navigationMapView.mapView.mapboxMap.style
            if style.sourceExists(withId: trackStyledFeature.sourceIdentifier) {
                let feature = Feature(geometry: .lineString(trackStyledFeature.lineString))
                try style.updateGeoJSONSource(withId: trackStyledFeature.sourceIdentifier,
                                              geoJSON: .feature(feature))
            }
            
            if style.sourceExists(withId: rawTrackStyledFeature.sourceIdentifier) {
                let feature = Feature(geometry: .lineString(rawTrackStyledFeature.lineString))
                try style.updateGeoJSONSource(withId: rawTrackStyledFeature.sourceIdentifier,
                                              geoJSON: .feature(feature))
            }
        } catch {
            NSLog("Error occured while performing operation with source: \(error.localizedDescription).")
        }
    }
    
    func addStyledFeature(_ styledFeature: StyledFeature) {
        do {
            let style = navigationMapView.mapView.mapboxMap.style
            var source = GeoJSONSource()
            source.data = .geometry(.lineString(styledFeature.lineString))
            try style.addSource(source, id: styledFeature.sourceIdentifier)
            
            var layer = LineLayer(id: styledFeature.layerIdentifier)
            layer.source = styledFeature.sourceIdentifier
            layer.lineWidth = .constant(styledFeature.lineWidth)
            layer.lineColor = .constant(.init(styledFeature.color))
            try style.addPersistentLayer(layer)
        } catch {
            NSLog("Failed to perform operation with error: \(error.localizedDescription).")
        }
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
        
        // Identify the current road and upcoming road.
        var statusString = "Currently on \(edgeNames(identifier: currentEdgeIdentifier).joined(separator: " / ")), approaching \(edgeNames(identifier: nextEdgeIdentifier).joined(separator: " / "))"
        
        // If there is an upcoming intersection, include the names of the cross streets.
        let branchEdgeIdentifiers = startingEdge.outletEdges.suffix(from: 1).map({ $0.identifier })
        if !branchEdgeIdentifiers.isEmpty {
            let branchNames = branchEdgeIdentifiers.flatMap { edgeNames(identifier: $0) }
            statusString += " at \(branchNames.joined(separator: ", "))"
        }
        
        // Print the current road, upcoming road, and cross streets.
        print(statusString)
    }
    
    func edgeNames(identifier: RoadGraph.Edge.Identifier) -> [String] {
        let passiveLocationManager = (navigationMapView.mapView.location.locationProvider as? PassiveLocationProvider)?.locationManager
        guard let metadata = passiveLocationManager?.roadGraph.edgeMetadata(edgeIdentifier: identifier) else {
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
