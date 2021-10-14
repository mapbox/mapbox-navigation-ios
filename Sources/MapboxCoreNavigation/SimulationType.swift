import Foundation

/**
 The simulation intent type. Used for describing the intent to start simulation of the navigation service.
 */
public enum SimulationIntent: Int {
    /**
     The simulation starts because of manual choice.
     */
    case manual
    
    /**
     The simulation starts because of poor GPS signal.
     */
    case poorGPS
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
 The simulation state type. Used for notifying users of the change of navigation service simulation status.
 */
public enum SimulationState: Int {
    
    /**
     The navigation service will begin simulation.
     */
    case willBeginSimulation
    
    /**
     The navigation service did begin simulation.
     */
    case didBeginSimulation
    
    /**
     The navigation service is in simulation.
     */
    case inSimulation
    
    /**
     The navigation service will end simulation.
     */
    case willEndSimulation
    
    /**
     The navigation service did end simulation.
     */
    case didEndSimulation
    
    /**
     The navigation service isn't in simulation.
     */
    case notInSimulation
}
