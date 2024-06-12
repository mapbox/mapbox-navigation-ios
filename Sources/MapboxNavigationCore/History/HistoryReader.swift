import Foundation
import MapboxNavigationNative

/// Digest of history file contents produced by ``HistoryReader``.
public struct History {
    /// Array of recorded events in chronological order.
    public fileprivate(set) var events: [any HistoryEvent] = []

    /// Initial ``NavigationRoutes`` that was set to the Navigator.
    ///
    /// Can be `nil` if current file is a free drive recording or if history recording was started after such event. In
    /// latter case this property may contain another ``NavigationRoutes`` which was, for example, set as a result of a
    /// reroute event.
    public var initialRoute: NavigationRoutes? {
        return (events.first { event in
            return event is RouteAssignmentHistoryEvent
        } as? RouteAssignmentHistoryEvent)?.navigationRoutes
    }

    /// Array of location updates.
    public var rawLocations: [CLLocation] {
        return events.compactMap {
            return ($0 as? LocationUpdateHistoryEvent)?.location
        }
    }

    func rawLocationsShiftedToPresent() -> [CLLocation] {
        return rawLocations.enumerated().map { CLLocation(
            coordinate: $0.element.coordinate,
            altitude: $0.element.altitude,
            horizontalAccuracy: $0.element.horizontalAccuracy,
            verticalAccuracy: $0.element.verticalAccuracy,
            course: $0.element.course,
            speed: $0.element.speed,
            timestamp: Date() + TimeInterval($0.offset)
        ) }
    }
}

/// Provides event-by-event access to history files contents.
///
/// Supports `pbf.gz` files. History files are created by ``HistoryRecording/stopRecordingHistory(writingFileWith:)``
/// and saved to ``HistoryRecordingConfig/historyDirectoryURL``.
public struct HistoryReader: AsyncSequence, Sendable {
    public typealias Element = HistoryEvent

    /// Configures ``HistoryReader`` parsing options.
    public struct ReadOptions: OptionSet, Sendable {
        public var rawValue: UInt
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        /// Reader will skip ``UnknownHistoryEvent`` events.
        public static let omitUnknownEvents = ReadOptions(rawValue: 1)
    }

    public struct AsyncIterator: AsyncIteratorProtocol {
        private let historyReader: MapboxNavigationNative.HistoryReader
        private let readOptions: ReadOptions?

        init(historyReader: MapboxNavigationNative.HistoryReader, readOptions: ReadOptions? = nil) {
            self.historyReader = historyReader
            self.readOptions = readOptions
        }

        public mutating func next() async -> (any HistoryEvent)? {
            guard let record = historyReader.next() else {
                return nil
            }
            let event = await process(record: record)
            if readOptions?.contains(.omitUnknownEvents) ?? false, event is UnknownHistoryEvent {
                return await next()
            }
            return event
        }

        private func process(record: HistoryRecord) async -> (any HistoryEvent)? {
            let timestamp = TimeInterval(Double(record.timestampNanoseconds) / 1e9)
            switch record.type {
            case .setRoute:
                guard let event = record.setRoute,
                      let navigationRoutes = await process(setRoute: event) else { break }
                return RouteAssignmentHistoryEvent(
                    timestamp: timestamp,
                    navigationRoutes: navigationRoutes
                )
            case .updateLocation:
                guard let event = record.updateLocation else { break }
                return LocationUpdateHistoryEvent(
                    timestamp: timestamp,
                    location: process(updateLocation: event)
                )
            case .getStatus:
                guard let event = record.getStatus else { break }
                return StatusUpdateHistoryEvent(
                    timestamp: timestamp,
                    monotonicTimestamp: TimeInterval(Double(
                        event
                            .monotonicTimestampNanoseconds
                    ) / 1e9),
                    status: event.result
                )
            case .pushHistory:
                guard let event = record.pushHistory else { break }
                return UserPushedHistoryEvent(
                    timestamp: timestamp,
                    type: event.type,
                    properties: event.properties
                )
            @unknown default:
                break
            }
            return UnknownHistoryEvent(timestamp: timestamp)
        }

        private func process(setRoute: SetRouteHistoryRecord) async -> NavigationRoutes? {
            guard let routeRequest = setRoute.routeRequest,
                  let routeResponse = setRoute.routeResponse,
                  routeRequest != "{}", routeResponse != "{}",
                  let responseData = routeResponse.data(using: .utf8)
            else {
                // Route reset
                return nil
            }
            let routeIndex = Int(setRoute.routeIndex)
            let routes = RouteParser.parseDirectionsResponse(
                forResponseDataRef: .init(data: responseData),
                request: routeRequest,
                routeOrigin: setRoute.origin
            )

            guard routes.isValue(),
                  var nativeRoutes = routes.value as? [RouteInterface],
                  nativeRoutes.indices.contains(routeIndex)
            else {
                assertionFailure("Failed to parse set route event")
                return nil
            }
            let routesData = RouteParser.createRoutesData(
                forPrimaryRoute: nativeRoutes.remove(at: routeIndex),
                alternativeRoutes: nativeRoutes
            )
            return try? await NavigationRoutes(routesData: routesData)
        }

        private func process(updateLocation: UpdateLocationHistoryRecord) -> CLLocation {
            return CLLocation(updateLocation.location)
        }
    }

    public func makeAsyncIterator() -> AsyncIterator {
        return AsyncIterator(
            historyReader: MapboxNavigationNative.HistoryReader(path: fileUrl.path),
            readOptions: readOptions
        )
    }

    private let fileUrl: URL
    private let readOptions: ReadOptions?

    /// Creates a new ``HistoryReader``
    ///
    /// - parameter fileUrl: History file to read through.
    public init?(fileUrl: URL, readOptions: ReadOptions? = nil) {
        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            return nil
        }
        self.fileUrl = fileUrl
        self.readOptions = readOptions
    }

    /// Creates a new ``HistoryReader`` instance.
    ///
    /// - parameter data: History data to read through.
    public init?(data: Data, readOptions: ReadOptions? = nil) {
        let temporaryURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        do {
            try data.write(to: temporaryURL, options: .withoutOverwriting)
        } catch {
            return nil
        }
        self.fileUrl = temporaryURL
        self.readOptions = readOptions
    }

    /// Performs synchronous full file read.
    ///
    /// This will read current file from beginning to the end.
    /// - returns: ``History`` containing extracted events.
    public func parse() async throws -> History {
        var result = History()
        for await event in self {
            result.events.append(event)
        }
        return result
    }
}
