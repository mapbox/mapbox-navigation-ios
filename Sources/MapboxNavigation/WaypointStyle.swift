import Foundation

/**
 Enum denoting the types of the destination waypoint highlighting on arrival.
 */
public enum WaypointStyle: Int {
    /**
     Do not highlight destination waypoint on arrival. Destination annotation is always shown by default.
     */
    case annotation
    
    /**
     Highlight destination building on arrival in 2D. In case if destination building wasn't found only annotation will be shown.
     */
    case building
    
    /**
     Highlight destination building on arrival in 3D. In case if destination building wasn't found only annotation will be shown.
     */
    case extrudedBuilding
}
