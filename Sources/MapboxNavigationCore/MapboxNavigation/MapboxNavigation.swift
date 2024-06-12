import Combine
import Foundation

/// An entry point for interacting with the Mapbox Navigation SDK.
@MainActor
public protocol MapboxNavigation {
    /// Returns a ``RoutingProvider`` used by SDK
    func routingProvider() -> RoutingProvider

    /// Provides control over main navigation states and transitions between them.
    func tripSession() -> SessionController

    // TODO: add replaying controls

    /// Provides access to ElectronicHorizon events.
    func electronicHorizon() -> ElectronicHorizonController

    /// Provides control over various aspects of the navigation process, mainly Active Guidance.
    func navigation() -> NavigationController

    /// Provides access to observing and posting various navigation events and user feedback.
    func eventsManager() -> NavigationEventsManager

    /// Provides ability to push custom history events to the log.
    func historyRecorder() -> HistoryRecording?

    /// Provides access to the copilot service.
    ///
    /// Use this to get fine details of the current navigation session and manually control it.
    func copilot() -> CopilotService?
}

extension MapboxNavigator:
    SessionController,
    ElectronicHorizonController,
    NavigationController
{
    public var locationMatching: AnyPublisher<MapMatchingState, Never> {
        mapMatching
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    var currentLocationMatching: MapMatchingState? {
        currentMapMatching
    }
}
