import MapboxMaps

extension MapboxMap {
    func mockJsonStyle(with layers: [[String: String]] = []) -> String {
        let styleJSONObject: [String: Any] = [
            "version": 8,
            "center": [
                -122.385563, 37.763330,
            ],
            "zoom": 15,
            "sources": [
                "composite": [
                    "url": "mapbox://mapbox.mapbox-streets-v8,mapbox.mapbox-terrain-v2",
                    "type": "vector",
                ],
                "custom": [
                    "url": "https://api.example.com/tilejson.json",
                    "type": "raster",
                ],
            ],
            "layers": layers,
        ]

        return ValueConverter.toJson(forValue: styleJSONObject)
    }
}
