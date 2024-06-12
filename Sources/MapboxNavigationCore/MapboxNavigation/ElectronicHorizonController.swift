import Combine
import Foundation

/// Provides access to ElectronicHorizon events.
@MainActor
public protocol ElectronicHorizonController: Sendable {
    /// Posts updates on EH.
    var eHorizonEvents: AnyPublisher<EHorizonStatus, Never> { get }
    /// Provides access to the road graph network and related road objects.
    var roadMatching: RoadMatching { get }

    /// Toggles ON EH updates.
    ///
    /// Requires ``ElectronicHorizonConfig`` to be provided.
    func startUpdatingEHorizon()
    /// Toggles OFF EH updates.
    ///
    /// Requires ``ElectronicHorizonConfig`` to be provided.
    func stopUpdatingEHorizon()
}
