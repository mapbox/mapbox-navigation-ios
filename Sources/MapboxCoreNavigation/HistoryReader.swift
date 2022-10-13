import Foundation
import MapboxNavigationNative

/// Digest of history file contents produced by `HistoryReader`.
public struct History {
    /// Array of recorded events in chronological order.
    public fileprivate(set) var events: [HistoryEvent] = []
    
    /// Initial `IndexedRouteResponse` that was set to the Navigator.
    ///
    /// Can be `nil` if current file is a free drive recording or if history recording was started after such event. In latter case this property may contain another `IndexedRouteResponse` which was, for example, set as a result of a reroute event.
    public var initialRoute: IndexedRouteResponse? {
        return (events.first { event in
            return event is RouteAssignmentHistoryEvent
        } as? RouteAssignmentHistoryEvent)?.routeResponse
    }
    
    /// Array of location updates.
    public var rawLocations: [CLLocation] {
        return events.compactMap {
            return ($0 as? LocationUpdateHistoryEvent)?.location
        }
    }
}

/// Provides event-by-event access to history files contents.
///
/// Supports `pbf.gz` files. History files are created by `HistoryRecording.stopRecordingHistory(writingFileWith:)` and saved to `HistoryRecording.historyDirectoryURL`.
public struct HistoryReader: Sequence {
    /// Configures `HistoryReader` parsing options.
    public struct ReadOptions: OptionSet {
        public var rawValue: UInt
        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
        /// Reader will skip `UnknownHistoryEvent` events.
        static public let omitUnknownEvents = ReadOptions(rawValue: 1)
    }
    
    public struct Iterator: IteratorProtocol {
        public typealias Element = HistoryEvent
        
        private let historyReader: MapboxNavigationNative.HistoryReader
        private let readOptions: ReadOptions?
        
        init(historyReader: MapboxNavigationNative.HistoryReader, readOptions: ReadOptions? = nil) {
            self.historyReader = historyReader
            self.readOptions = readOptions
        }
        
        public mutating func next() -> HistoryEvent? {
            guard let record = historyReader.next() else {
                return nil
            }
            let event = process(record: record)
            if readOptions?.contains(.omitUnknownEvents) ?? false && event is UnknownHistoryEvent {
                return next()
            }
            return event
        }
        
        private func process(record: HistoryRecord) -> HistoryEvent? {
            let timestamp = TimeInterval(Double(record.timestampNanoseconds) / 1e9)
            switch record.type {
            case .setRoute:
                guard let event = record.setRoute,
                      let routeResponse = process(setRoute: event) else { break }
                return RouteAssignmentHistoryEvent(timestamp: timestamp,
                                                   routeResponse: routeResponse)
            case .updateLocation:
                guard let event = record.updateLocation else { break }
                return LocationUpdateHistoryEvent(timestamp: timestamp,
                                                  location: process(updateLocation: event))
            case .getStatus:
                guard let event = record.getStatus else { break }
                return StatusUpdateHistoryEvent(timestamp: timestamp,
                                                monotonicTimestamp: TimeInterval(Double(event.monotonicTimestampNanoseconds) / 1e9),
                                                status: event.result)
            case .pushHistory:
                guard let event = record.pushHistory else { break }
                return PushRecordHistoryEvent(timestamp: timestamp,
                                              type: event.type,
                                              properties: event.properties)
            @unknown default:
                break
            }
            return UnknownHistoryEvent(timestamp: timestamp)
        }
        
        private func process(setRoute: SetRouteHistoryRecord) -> IndexedRouteResponse? {
            guard let routeRequest = setRoute.routeRequest,
                  let routeResponse = setRoute.routeResponse,
                  (routeRequest != "{}" && routeResponse != "{}")
            else {
                // Route reset
                return nil
            }
            guard let decodedInfo = RerouteController.decode(routeRequest: routeRequest, routeResponse: routeResponse),
                  let routes = decodedInfo.routeResponse.routes,
                  routes.indices.contains(Int(setRoute.routeIndex))
            else {
                assertionFailure("Failed to parse set route event")
                return nil
            }

            return IndexedRouteResponse(
                routeResponse: decodedInfo.routeResponse,
                routeIndex: Int(setRoute.routeIndex)
            )
        }

        private func process(updateLocation: UpdateLocationHistoryRecord) -> CLLocation {
            return CLLocation(updateLocation.location)
        }
    }
    
    public func makeIterator() -> Iterator {
        return Iterator(historyReader: MapboxNavigationNative.HistoryReader(path: fileUrl.path),
                        readOptions: readOptions)
    }
    
    private let fileUrl: URL
    private let readOptions: ReadOptions?
    
    /// Creates new `HistoryReader`
    ///
    /// - parameter fileUrl: History file to read through.
    public init?(fileUrl: URL, readOptions: ReadOptions? = nil) {
        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            return nil
        }
        self.fileUrl = fileUrl
        self.readOptions = readOptions
    }
    
    /// Creates new `HistoryReader`
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
    /// - returns: `History` containing extracted events.
    public func parse() throws -> History {
        var result = History()
        for event in self {
            result.events.append(event)
        }
        return result
    }
}
