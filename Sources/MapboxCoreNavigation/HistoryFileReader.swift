import Foundation
import MapboxNavigationNative

/// Digest of history file contents produced by `HistoryFileReader`.
public struct HistoryFileDump {
    /// Initial `IndexedRouteResponse` that was set to the Navigator.
    ///
    /// Can be `nil` if current file is a free drive recording or if history recording was started after such event. In latter case this property may contain another `IndexedRouteResponse` which was, for example, set as a result of a reroute event.
    public fileprivate(set) var initialRoute: IndexedRouteResponse?
    /// Stream of location updates.
    public fileprivate(set) var rawLocations: [CLLocation] = []
}

/// Provides event-by-event access to history files contents.
///
/// Supports `pbf.gz` files.
public final class HistoryFileReader {
    /// Type of error occured during parcing history file.
    public enum Error: Swift.Error {
        /// Parsing did not complete due to user aborted the operation.
        case cancelled
        /// File by the given URL is not found.
        case fileNotFound
        /// Reader could not parse the file contents.
        case incorrectFile
    }
    
    /// Path to the history file.
    public private(set) var fileUrl: URL
    private lazy var historyReader: HistoryReader = HistoryReader(path: fileUrl.path)
    
    /// creates new `HistoryFileReader`
    ///
    /// - parameter fileUrl: History file to read through.
    public init(fileUrl: URL) {
        self.fileUrl = fileUrl
    }
    
    /// Performs asynchronous full file read.
    ///
    /// This will read current file from beginning to the end, regardless of possible progress by `readNext()`.
    /// - parameter completion: Completion block to be called when read with successfull or encountered error otherwise.
    public func asyncRead(completion: @escaping (Result<HistoryFileDump, Error>) -> Void) throws -> Void {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else {
                completion(.failure(Error.cancelled))
                return
            }
            do {
                completion(.success(try self.syncRead()))
            } catch {
                completion(.failure(error as! HistoryFileReader.Error))
            }
        }
    }
    
    /// Performs synchronous full file read.
    ///
    /// This will read current file from beginning to the end, regardless of possible progress by `readNext()`.
    /// - returns: `HistoryFileDump` containing extracted events.
    public func syncRead() throws -> HistoryFileDump {
        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            throw Error.fileNotFound
        }
        
        let reader = HistoryReader(path: fileUrl.path)
        var result = HistoryFileDump()
        var anyRecordFound = false
        while let record = reader.next() {
            anyRecordFound = true
            guard let event = process(record: record) else {
                continue
            }
            switch event {
            case let setRoute as HistorySetRoute:
                result.initialRoute = setRoute.routeResponse
            case let updateLocation as HistoryUpdateLocation:
                result.rawLocations.append(updateLocation.location)
            default:
                // ignored
                break
            }
        }
        if anyRecordFound == false {
            throw Error.incorrectFile
        }
        return result
    }

    /// Reads history file event-by-event.
    ///
    /// - returns: `nil` if file is invalid or if there are no more events.
    public func readNext() throws -> HistoryEvent? {
        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            throw Error.fileNotFound
        }
        
        if let record = historyReader.next() {
            return process(record: record)
        } else {
            return nil
        }
    }
    
    private func process(record: HistoryRecord) -> HistoryEvent? {
        let timestamp = TimeInterval(Double(record.timestampNanoseconds) / 1e9)
        switch record.type {
        case .setRoute:
            guard let event = record.setRoute,
                  let routeResponse = process(setRoute: event) else { break }
            return HistorySetRoute(timestamp: timestamp,
                                   routeResponse: routeResponse)
        case .updateLocation:
            guard let event = record.updateLocation else { break }
            return HistoryUpdateLocation(timestamp: timestamp,
                                         location: process(updateLocation: event))
        default:
            break
        }
        return HistoryEvent(timestamp: timestamp)
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
