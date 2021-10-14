import Foundation

public enum SimulationIntent: Int {
    case manual, poorGPS
}

/**
 The simulation mode type. Used for setting the simulation mode of the navigation service.
 */
public enum SimulationMode: Int {
    /**
     A setting of `.onPoorGPS` will enable simulation when we do not recieve a location update after the `poorGPSPatience` threshold has elapsed.
     */
    case onPoorGPS

    /**
     A setting of `.always` will simulate route progress at all times.
     */
    case always

    /**
     A setting of `.never` will never enable the location simulator, regardless of circumstances.
     */
    case never
    
    /**
     A setting of `.inTunnels` will enable simulation when two conditions are met: we do not recieve a location update after the `poorGPSPatience` threshold has elapsed and SDK detects current location as a [tunnel](https://wiki.openstreetmap.org/wiki/Key:tunnel).
     */
    case inTunnels
}

/**
 The simulating update type. Used for notifying users of the begin and end of navigation service simulating status.
 */
public enum SimulatingUpdate: Int {
    
    /**
     The navigation service will begin simulating.
     */
    case willBeginSimulating
    
    /**
     The navigation service did begin simulating.
     */
    case didBeginSimulating
    
    /**
     The navigation service is in simulating.
     */
    case inSimulating
    
    /**
     The navigation service will end simulating.
     */
    case willEndSimulating
    
    /**
     The navigation service did end simulating.
     */
    case didEndSimulating
    
    /**
     The navigation service isn't in simulating.
     */
    case notInSimulating
}
