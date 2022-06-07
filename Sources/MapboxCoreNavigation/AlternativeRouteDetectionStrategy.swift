import Foundation

/**
 Options to configure fetching and detecting `AlternativeRoute`s during navigation.
 */
public struct AlternativeRouteDetectionStrategy {
    /**
     Enables requesting for new alternative routes after passing a fork (intersection) where another alternative route branches.
     
     Default value is `true`.
     */
    public var refreshesAfterPassingDeviation = true
    
    /**
     Enables periodic requests when there are no known alternative routes yet.
     
     Default value is `noPeriodicRefresh`.
     */
    public var refreshesWhenNoAvailableAlternatives: RefreshOnEmpty = .noPeriodicRefresh
    /**
     Describes how periodic requests for `AlternativeRoute`s should be made.
     */
    public enum RefreshOnEmpty {
        /**
         Will not do periodic requests for alternatives.
         */
        case noPeriodicRefresh
        /**
         Requests will be made with given time interval. Using this option may result in increased traffic consumption, but  help detect alternative routes which may appear during road conditions change during the trip.
         Default values time interval is `3 minutes`.
         */
        case refreshesPeriodically(TimeInterval = 180)
    }
    
    /**
     Creates new `AlternativeRouteDetectionStrategy` instance.
     */
    public init(refreshesAfterPassingDeviation: Bool = true,
                refreshesWhenNoAvailableAlternatives: RefreshOnEmpty = .noPeriodicRefresh) {
        self.refreshesAfterPassingDeviation = refreshesAfterPassingDeviation
        self.refreshesWhenNoAvailableAlternatives = refreshesWhenNoAvailableAlternatives
    }
}
