import Foundation
import Mapbox
import MapboxDirections


struct ZoomLevelBounds {
    var minimum: Int
    var maximum: Int
}

class OfflineService {
    class func downloadTiles(for route: Route, named name: String, style: Style, zoomBounds: ZoomLevelBounds) {
        guard let coordinates = route.coordinates else { return }
        let coordCount = UInt(coordinates.count)
        let polyline = MGLPolyline(coordinates: coordinates, count: coordCount)
        
        OfflineServiceBridge.downloadTiles(with: polyline, name: name, style: style, minimumZoomLevel: zoomBounds.minimum, maximumZoomLevel: zoomBounds.maximum)
    }
}

