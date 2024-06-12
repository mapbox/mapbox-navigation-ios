import _MapboxNavigationHelpers
import Combine
import CoreLocation
import Foundation

/// Provides controls over the history replaying playback.
///
/// This class is used together with ``LocationClient/historyReplayingValue(with:)`` to create and control history files
/// playback. Use this instance to observe playback events, seek, pause and controll playback speed.
public final class HistoryReplayController: Sendable {
    private struct State: Sendable {
        weak var delegate: HistoryReplayDelegate?
        var currentEvent: (any HistoryEvent)?
        var isPaused: Bool
        var replayStart: TimeInterval?
        var speedMultiplier: Double
    }

    private let _state: UnfairLocked<State>

    /// ``HistoryReplayDelegate`` instance for observing replay events.
    public weak var delegate: HistoryReplayDelegate? {
        get { _state.read().delegate }
        set { _state.mutate { $0.delegate = newValue } }
    }

    /// Playback speed.
    ///
    /// May be useful for reaching the required portion of the history trace.
    /// - important: Too high values may result in navigator not being able to correctly process the events and thus
    /// leading to the undefined behavior. Also, the value must be greater than 0.
    public var speedMultiplier: Double {
        get { _state.read().speedMultiplier }
        set {
            precondition(newValue > 0.0, "HistoryReplayController.speedMultiplier must be greater than 0!")
            _state.mutate { $0.speedMultiplier = newValue }
        }
    }

    /// A stream of location updates contained in the history trace.
    public var locations: AnyPublisher<CLLocation, Never> {
        _locations.read().eraseToAnyPublisher()
    }

    private let _locations: UnfairLocked<PassthroughSubject<CLLocation, Never>> = .init(.init())
    private var currentEvent: (any HistoryEvent)? {
        get { _state.read().currentEvent }
        set { _state.mutate { $0.currentEvent = newValue } }
    }

    private let eventsIteratorLocked: UnfairLocked<EventsIterator>
    private func getNextEvent() async -> (any HistoryEvent)? {
        var iterator = eventsIteratorLocked.read()
        let result = try? await iterator.next()
        eventsIteratorLocked.update(iterator)
        return result
    }

    /// Indicates if the playback was paused.
    public var isPaused: Bool {
        _state.read().isPaused
    }

    private var replayStart: TimeInterval? {
        get { _state.read().replayStart }
        set { _state.mutate { $0.replayStart = newValue } }
    }

    /// Creates new ``HistoryReplayController`` instance.
    /// - parameter history: Parsed ``History`` instance, containing stream of events for playback.
    public convenience init(history: History) {
        self.init(
            eventsIterator: .init(
                datasource: .historyFile(history, 0)
            )
        )
    }

    /// Creates new ``HistoryReplayController`` instance.
    /// - parameter historyReader: ``HistoryReader`` instance, used to fetch and replay the history events.
    public convenience init(historyReader: HistoryReader) {
        self.init(
            eventsIterator: .init(
                datasource: .historyIterator(
                    historyReader.makeAsyncIterator()
                )
            )
        )
    }

    fileprivate init(eventsIterator: EventsIterator) {
        self._state = .init(
            .init(
                delegate: nil,
                currentEvent: nil,
                isPaused: true,
                replayStart: nil,
                speedMultiplier: 1
            )
        )
        self.eventsIteratorLocked = .init(eventsIterator)
    }

    /// Seeks forward to the specific event.
    ///
    /// When found, this event will be the next one processed and reported via the ``HistoryReplayController/delegate``.
    /// If such event was not found, controller will seek to the end of the trace.
    /// It is not possible to seek backwards.
    /// - parameter event: ``HistoryEvent`` to seek to.
    /// - returns: `True` if seek was successfull, `False` - otherwise.
    public func seekTo(event: any HistoryEvent) async -> Bool {
        if replayStart == nil {
            currentEvent = await getNextEvent()
            replayStart = currentEvent?.timestamp
        }
        guard replayStart ?? .greatestFiniteMagnitude <= event.timestamp,
              currentEvent?.timestamp ?? .greatestFiniteMagnitude <= event.timestamp
        else {
            return false
        }
        var nextEvent = if let currentEvent {
            currentEvent
        } else {
            await getNextEvent()
        }

        while let checkedEvent = nextEvent,
              !checkedEvent.compare(to: event)
        {
            nextEvent = await getNextEvent()
        }
        currentEvent = nextEvent
        guard nextEvent != nil else {
            return false
        }
        return true
    }

    /// Seeks forward to the specific time offset, relative to the beginning of the replay.
    ///
    /// The next event reported via the ``HistoryReplayController/delegate`` will have it's offset relative to the
    /// beginning of the replay be not less then `offset` parameter.
    /// It is not possible to seek backwards.
    /// - parameter offset: Seek to this offset, relative to the beginning of the replay. If `offset` is greater then
    /// replay total duration - controller will seek to the end of the trace.
    /// - returns: `True` if seek was successfull, `False` - otherwise.
    public func seekTo(offset: TimeInterval) async -> Bool {
        if let currentEvent,
           let currentOffset = eventOffest(currentEvent),
           currentOffset > offset
        {
            return false
        }

        var nextEvent = if let currentEvent {
            currentEvent
        } else {
            await getNextEvent()
        }
        replayStart = replayStart ?? nextEvent?.timestamp

        while let checkedEvent = nextEvent,
              eventOffest(checkedEvent) ?? .greatestFiniteMagnitude < offset
        {
            nextEvent = await getNextEvent()
        }
        currentEvent = nextEvent
        guard nextEvent != nil else {
            return false
        }
        return true
    }

    /// Starts of resumes the playback.
    public func play() {
        guard isPaused else { return }
        _state.mutate {
            $0.isPaused = false
        }
        processEvent(currentEvent)
    }

    /// Pauses the playback.
    public func pause() {
        _state.mutate {
            $0.isPaused = true
        }
    }

    /// Manually pushes the location, as if it was in the replay.
    ///
    /// May be useful to setup the replay by providing initial location to begin with.
    /// - parameter location: `CLLocation` to be pushed through the replay.
    public func push(location: CLLocation) {
        _locations.read().send(location)
    }

    /// Replaces history events in the playback queue.
    /// - parameter history: Parsed ``History`` instance, containing stream of events for playback.
    public func push(events history: History) {
        eventsIteratorLocked.update(
            .init(
                datasource: .historyFile(history, 0)
            )
        )
    }

    /// Replaces history events in the playback queue.
    /// - parameter historyReader: ``HistoryReader`` instance, used to fetch and replay the history events.
    public func push(events historyReader: HistoryReader) {
        eventsIteratorLocked.update(
            .init(
                datasource: .historyIterator(
                    historyReader.makeAsyncIterator()
                )
            )
        )
    }

    /// Clears the playback queue.
    public func clearEvents() {
        eventsIteratorLocked.update(.init(datasource: nil))
        currentEvent = nil
        replayStart = nil
    }

    /// Calculates event's time offset, relative to the beginning of the replay.
    ///
    /// It does not check if passed event is actually in the replay. The replay must be started (at least 1 event should
    /// be processed), before this method could calculate offsets.
    /// - parameter event: An event to  calculate it's relative time offset.
    /// - returns: Event's time offset, relative to the beginning of the replay, or `nil` if current replay was not
    /// started yet.
    public func eventOffest(_ event: any HistoryEvent) -> TimeInterval? {
        replayStart.map { event.timestamp - $0 }
    }

    func tick() async {
        var eventDelay = currentEvent?.timestamp
        currentEvent = await getNextEvent()
        guard let currentEvent else {
            Task { @MainActor in
                delegate?.historyReplayControllerDidFinishReplay(self)
            }
            return
        }
        if replayStart == nil {
            replayStart = currentEvent.timestamp
        }

        eventDelay = currentEvent.timestamp - (eventDelay ?? currentEvent.timestamp)
        DispatchQueue.main.asyncAfter(deadline: .now() + (eventDelay ?? 0.0) / speedMultiplier) { [weak self] in
            guard let self else { return }
            processEvent(currentEvent)
        }
    }

    private func processEvent(_ event: (any HistoryEvent)?) {
        guard !isPaused else {
            return
        }
        defer {
            Task.detached { [self] in
                await self.tick()
            }
        }
        guard let event else { return }
        switch event {
        case let locationEvent as LocationUpdateHistoryEvent:
            _locations.read().send(locationEvent.location)
        case let setRouteEvent as RouteAssignmentHistoryEvent:
            delegate?.historyReplayController(
                self,
                wantsToSetRoutes: setRouteEvent.navigationRoutes
            )
        default:
            break
        }
        delegate?.historyReplayController(self, didReplayEvent: event)
    }
}

/// Delegate for ``HistoryReplayController``.
///
/// Has corresponding methods to observe when particular event has ocurred or when the playback is finished.
public protocol HistoryReplayDelegate: AnyObject, Sendable {
    /// Called after each ``HistoryEvent`` was handled by the ``HistoryReplayController``.
    /// - parameter controller: A ``HistoryReplayController`` which has handled the event.
    /// - parameter event: ``HistoryEvent`` that was just replayed.
    func historyReplayController(_ controller: HistoryReplayController, didReplayEvent event: any HistoryEvent)
    /// Called when ``HistoryReplayController`` has reached a ``RouteAssignmentHistoryEvent`` and reports that new
    /// ``NavigationRoutes`` should be set to the navigator.
    /// - parameter controller: A ``HistoryReplayController`` which has handled the event.
    /// - parameter navigationRoutes: ``NavigationRoutes`` to be set to the navigator.
    func historyReplayController(
        _ controller: HistoryReplayController,
        wantsToSetRoutes navigationRoutes: NavigationRoutes
    )
    /// Called when ``HistoryReplayController`` has reached the end of the replay and finished.
    ///  - parameter controller: The related ``HistoryReplayController``.
    func historyReplayControllerDidFinishReplay(_ controller: HistoryReplayController)
}

extension LocationClient {
    /// Creates a simulation ``LocationClient`` which will replay locations and other events from the history file.
    /// - parameter controller: ``HistoryReplayController`` instance used to control and observe the playback.
    /// - returns: ``LocationClient``, configured for replaying the history trace.
    public static func historyReplayingValue(with controller: HistoryReplayController) -> Self {
        return Self(
            locations: controller.locations,
            headings: Empty().eraseToAnyPublisher(),
            startUpdatingLocation: { controller.play() },
            stopUpdatingLocation: { controller.pause() },
            startUpdatingHeading: {},
            stopUpdatingHeading: {}
        )
    }
}

private struct EventsIterator: AsyncIteratorProtocol {
    typealias Element = any HistoryEvent
    enum Datasource {
        case historyIterator(HistoryReader.AsyncIterator)
        case historyFile(History, Int)
    }

    var datasource: Datasource?

    mutating func next() async throws -> (any HistoryEvent)? {
        switch datasource {
        case .historyIterator(var asyncIterator):
            defer {
                self.datasource = .historyIterator(asyncIterator)
            }
            // This line may trigger bindgen `Function HistoryReader::next called from a thread that is not owning the
            // object` error log, if the replayer was instantiated on the main thread.
            // This is not an error by itself, but it indicates possible thread safety violation using this iterator.
            return await asyncIterator.next()
        case .historyFile(let history, let index):
            defer {
                self.datasource = .historyFile(history, index + 1)
            }
            guard history.events.indices ~= index else {
                return nil
            }
            return history.events[index]
        case .none:
            return nil
        }
    }
}
