import Foundation

/**
 Options to configure fetching and detecting `AlternativeRoute`s during navigation.
 */
public struct AlternativeRouteDetectionOptions {
    public var enabled = true
    
    /**
     Enables requesting for new alternative routes after passing a fork (intersection) where another alternative route branches.
     
     Default value is `true`.
     */
    public var refreshAfterPassingDeviation = true
    
    /**
     Enables periodic requests when there are no known alternative routes yet.
     
     Requests will be made with `refreshInterval`. Using this option may result in increased traffic consumption, but  help detect alternative routes which may appear during road conditions change during the trip.
     Default values is `false`.
     */
    public var refreshWhenNoAvailableAlternatives = false
    /**
     Time interval for requests for alternatives to be made when `refreshWhenNoAvailableAlternatives` is enabled.
     
     Default value is `3 minutes`.
     */
    public var refreshInterval: TimeInterval = 3 * 60
    
    /**
     Creates new `AlternativeRoutesOptions`.
     
     - parameter refreshAfterPassingDeviation: A flag to request alternatives after passing a fork point.
     - parameter refreshWhenNoAvailableAlternatives: A flag to enable periodic requests for alternatives.
     - parameter refreshInterval: Time interval for periodic requests for alternatives.
     */
    public init(refreshAfterAlternativeFork: Bool = true,
                refreshWhenNoAvailableAlternatives: Bool = false,
                refreshInterval: TimeInterval = 3 * 60) {
        self.refreshAfterPassingDeviation = refreshAfterAlternativeFork
        self.refreshWhenNoAvailableAlternatives = refreshWhenNoAvailableAlternatives
        self.refreshInterval = refreshInterval
    }
}
