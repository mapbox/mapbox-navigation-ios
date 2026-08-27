import Foundation

/// Configuration for Navigator HD localization and HD tile access.
@_spi(MapboxInternal)
public struct HdNavigationConfig: Equatable, Sendable {
    /// When `true`, Navigator HD localization is enabled via custom config (`navigation.hd.enabled`).
    public var enabled: Bool

    /// HD tiles dataset identifier. Defaults to `"mapbox"` (matches Nav Native integration defaults).
    public var tilesDataset: String

    /// HD tiles version. An empty string lets Nav Native pick the latest server version.
    public var tilesVersion: String

    /// Minimum days between local and server HD tile versions before fetching a newer version.
    ///
    /// Matches Android `DomainTilesOptions.defaultHdTilesOptions()` (7 days). Only applies when
    /// ``tilesVersion`` is empty.
    public var minDaysBetweenServerAndLocalTilesVersion: Int

    /// HD navigation is disabled.
    public static let disabled = HdNavigationConfig(enabled: false)

    /// Creates HD navigation configuration.
    /// - Parameters:
    ///   - enabled: Enables Navigator HD localization when `true`.
    ///   - tilesDataset: HD tiles dataset passed to `TilesConfig.hdEndpointConfig`.
    ///   - tilesVersion: HD tiles version; empty string selects the latest server version.
    ///   - minDaysBetweenServerAndLocalTilesVersion: Minimum age in days before requesting a newer HD tile version.
    public init(
        enabled: Bool = false,
        tilesDataset: String = "mapbox",
        tilesVersion: String = "",
        minDaysBetweenServerAndLocalTilesVersion: Int = 7
    ) {
        self.enabled = enabled
        self.tilesDataset = tilesDataset
        self.tilesVersion = tilesVersion
        self.minDaysBetweenServerAndLocalTilesVersion = minDaysBetweenServerAndLocalTilesVersion
    }
}
