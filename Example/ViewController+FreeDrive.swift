import UIKit
import Turf
import MapboxCoreNavigation
import MapboxNavigation
import MapboxCoreMaps
import MapboxMaps

// MARK: - Free-driving methods

extension ViewController {
    
    func setupPassiveLocationManager(_ navigationMapView: NavigationMapView) {
        setupFreeDriveStyledFeatures()
        
        let passiveLocationDataSource = PassiveLocationDataSource()
        let passiveLocationManager = PassiveLocationManager(dataSource: passiveLocationDataSource)
        navigationMapView.mapView.locationManager.overrideLocationProvider(with: passiveLocationManager)
        
        subscribeForFreeDriveNotifications()
    }
    
    func subscribeForFreeDriveNotifications() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didUpdatePassiveLocation),
                                               name: .passiveLocationDataSourceDidUpdate,
                                               object: nil)
    }
    
    func unsubscribeFromFreeDriveNotifications() {
        NotificationCenter.default.removeObserver(self, name: .passiveLocationDataSourceDidUpdate, object: nil)
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
    }
    
    func updateFreeDriveStyledFeatures() {
        _ = navigationMapView.mapView.style.updateGeoJSON(for: trackStyledFeature.sourceIdentifier,
                                                          with: Feature(geometry: .lineString(trackStyledFeature.lineString)))
        
        _ = navigationMapView.mapView.style.updateGeoJSON(for: rawTrackStyledFeature.sourceIdentifier,
                                                          with: Feature(geometry: .lineString(rawTrackStyledFeature.lineString)))
    }
    
    func addStyledFeature(_ styledFeature: StyledFeature) {
        var source = GeoJSONSource()
        source.data = .geometry(.lineString(styledFeature.lineString))
        _ = navigationMapView.mapView.style.addSource(source: source,
                                                      identifier: styledFeature.sourceIdentifier)
        
        var layer = LineLayer(id: styledFeature.layerIdentifier)
        layer.source = styledFeature.sourceIdentifier
        layer.paint?.lineWidth = .constant(styledFeature.lineWidth)
        layer.paint?.lineColor = .constant(.init(color: styledFeature.color))
        _ = navigationMapView.mapView.style.addLayer(layer: layer)
    }
}
