import MapboxMaps

extension VectorSource {
    /// A dictionary associating known tile set identifiers with identifiers of source layers that contain road names.
    static let roadLabelLayerIdentifiersByTileSetIdentifier = [
        "mapbox.mapbox-streets-v8": "road",
        "mapbox.mapbox-streets-v7": "road_label",
    ]
}
