import UIKit
import Turf

/**
 Struct, which contains properties needed to render free-drive route line.
 */
struct StyledFeature {
    
    /**
     Identifier of the underlying `GeoJSONSource`.
     */
    var sourceIdentifier: String
    
    /**
     Identifier of the underlying `LineLayer`.
     */
    var layerIdentifier: String
    
    /**
     Color, which is used to style `LineLayer`.
     */
    var color: UIColor
    
    /**
     Line width, which is used to style `LineLayer`.
     */
    var lineWidth: Double
    
    /**
     Geometry of the free-drive route line.
     */
    var lineString: LineString
}
