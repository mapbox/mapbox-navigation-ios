import Foundation

/// Options to configure fetching, detecting, and accepting ``AlternativeRoute``s during navigation.
public struct AlternativeRoutesDetectionConfig: Equatable, Sendable {
    public struct AcceptionPolicy: OptionSet, Sendable {
        public typealias RawValue = UInt
        public var rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let unfiltered = AcceptionPolicy(rawValue: 1 << 0)
        public static let fasterRoutes = AcceptionPolicy(rawValue: 1 << 1)
        public static let shorterRoutes = AcceptionPolicy(rawValue: 1 << 2)
    }

    /// Enables requesting for new alternative routes after passing a fork (intersection) where another alternative
    /// route branches. The default value is `true`.
    @available(*, deprecated, message: "This feature no longer has any effect.")
    public var refreshesAfterPassingDeviation = true

    /// Enables periodic requests when there are no known alternative routes yet. The default value is
    /// ``AlternativeRoutesDetectionConfig/RefreshOnEmpty/noPeriodicRefresh``.
    @available(
        *,
        deprecated,
        message: "This feature no longer has any effect other then setting the refresh interval. Use 'refreshIntervalSeconds' instead to configure the refresh interval directly."
    )
    public var refreshesWhenNoAvailableAlternatives: RefreshOnEmpty = .noPeriodicRefresh {
        didSet {
            if let refreshIntervalSeconds = refreshesWhenNoAvailableAlternatives.refreshIntervalSeconds {
                self.refreshIntervalSeconds = refreshIntervalSeconds
            }
        }
    }

    /// Describes how periodic requests for ``AlternativeRoute``s should be made.
    @available(*, deprecated, message: "This feature no longer has any effect.")
    public enum RefreshOnEmpty: Equatable, Sendable {
        /// Will not do periodic requests for alternatives.
        case noPeriodicRefresh
        /// Requests will be made with the given time interval. Using this option may result in increased traffic
        /// consumption, but help detect alternative routes
        /// which may appear during road conditions change during the trip. The default value is `5 minutes`.
        case refreshesPeriodically(TimeInterval = AlternativeRoutesDetectionConfig.defaultRefreshIntervalSeconds)
    }

    public var acceptionPolicy: AcceptionPolicy

    /// The refresh alternative routes interval. 5 minutes by default. Minimum 30 seconds.
    public var refreshIntervalSeconds: TimeInterval

    /// Creates a new alternative routes detection configuration.
    ///
    /// - Parameters:
    ///   - refreshesAfterPassingDeviation: Enables requesting for new alternative routes after passing a fork
    /// (intersection) where another alternative route branches.
    ///     The default value is `true`.
    ///   - refreshesWhenNoAvailableAlternatives: Enables periodic requests when there are no known alternative routes
    /// yet. The default value is ``AlternativeRoutesDetectionConfig/RefreshOnEmpty/noPeriodicRefresh``.
    ///   - acceptionPolicy: The acceptance policy.
    @available(*, deprecated, message: "Use 'init(acceptionPolicy:refreshIntervalSeconds:)' instead.")
    public init(
        refreshesAfterPassingDeviation: Bool = true,
        refreshesWhenNoAvailableAlternatives: RefreshOnEmpty = .noPeriodicRefresh,
        acceptionPolicy: AcceptionPolicy = .unfiltered
    ) {
        self.refreshesAfterPassingDeviation = refreshesAfterPassingDeviation
        self.refreshesWhenNoAvailableAlternatives = refreshesWhenNoAvailableAlternatives
        self.acceptionPolicy = acceptionPolicy
        self.refreshIntervalSeconds = refreshesWhenNoAvailableAlternatives.refreshIntervalSeconds ?? Self
            .defaultRefreshIntervalSeconds
    }

    /// Creates a new alternative routes detection configuration.
    ///
    /// - Parameters:
    ///   - acceptionPolicy: The acceptance policy.
    ///   - refreshIntervalSeconds: The refresh alternative routes interval. 5 minutes by default. Minimum 30
    /// seconds.
    public init(
        acceptionPolicy: AcceptionPolicy = .unfiltered,
        refreshIntervalSeconds: TimeInterval = Self.defaultRefreshIntervalSeconds
    ) {
        self.acceptionPolicy = acceptionPolicy
        self.refreshIntervalSeconds = refreshIntervalSeconds
    }

    public static let defaultRefreshIntervalSeconds: TimeInterval = 300
}

@available(*, deprecated)
extension AlternativeRoutesDetectionConfig.RefreshOnEmpty {
    fileprivate var refreshIntervalSeconds: TimeInterval? {
        switch self {
        case .noPeriodicRefresh:
            return nil
        case .refreshesPeriodically(let value):
            return value
        }
    }
}
