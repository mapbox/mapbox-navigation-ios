import Foundation
import MapboxMaps

public enum PuckType {
    
    case puck2D(configuration: Puck2DConfiguration)
    
    case puck3D(configuration: Puck3DConfiguration)
    
    case `default`
    
}
