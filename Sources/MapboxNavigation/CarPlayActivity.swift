/**
 The activity during which a `CPTemplate` is displayed. This enumeration is used to distinguish between different templates during different phases of user interaction.
 */
public enum CarPlayActivity: Int {
    /**
     The user is browsing the map or searching for a destination.
     */
    case browsing
    
    /**
     The user is panning while browsing the map interface.
     */
    case panningInBrowsingMode
    
    /**
     The user is panning during active navigation.
     */
    case panningInNavigationMode
    
    /**
     The user is previewing a route or selecting among multiple routes.
     */
    case previewing
    
    /**
     The user is actively navigating along a route.
     */
    case navigating
}
