import Foundation
import MapboxNavigationNative

public struct HistoryFileDump {
    var initialRoute: IndexedRouteResponse?
    var rawLocations: [CLLocation] = []
}

public struct HistoryFileReader {
    public enum Error: Swift.Error {
        case fileNotFound
        case incorrectFile
    }
    
    public init() {}
    
    public func asyncRead(fileUrl: URL, completion: @escaping (Result<HistoryFileDump, Error>) -> Void) throws -> Void {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                completion(.success(try syncRead(fileUrl: fileUrl)))
            } catch {
                completion(.failure(error as! HistoryFileReader.Error))
            }
        }
    }
    
    public func syncRead(fileUrl: URL) throws -> HistoryFileDump {
        guard FileManager.default.fileExists(atPath: fileUrl.path) else {
            throw Error.fileNotFound
        }
        
        let reader = HistoryReader(path: fileUrl.path)
        var result = HistoryFileDump()
        var anyRecordFound = false
        while let record = reader.next() {
            anyRecordFound = true
            switch record.type {
            case .setRoute:
                guard let event = record.setRoute else { break }
                process(setRoute: event, result: &result)
            case .updateLocation:
                guard let event = record.updateLocation else { break }
                process(updateLocation: event, result: &result)
            default:
                // Ignored
                break
            }
        }
        if anyRecordFound == false {
            throw Error.incorrectFile
        }
        return result
    }

    private func process(setRoute: SetRouteHistoryRecord, result: inout HistoryFileDump) {
        guard result.initialRoute == nil else {
            // Read the first one only
            return
        }
        guard let routeRequest = setRoute.routeRequest,
              let routeResponse = setRoute.routeResponse,
              (routeRequest != "{}" && routeResponse != "{}")
        else {
            // Route reset
            return
        }
        guard let decodedInfo = RerouteController.decode(routeRequest: routeRequest, routeResponse: routeResponse),
              let routes = decodedInfo.routeResponse.routes,
              routes.indices.contains(Int(setRoute.routeIndex))
        else {
            assertionFailure("Failed to parse set route event")
            return
        }

        result.initialRoute = .init(
            routeResponse: decodedInfo.routeResponse,
            routeIndex: Int(setRoute.routeIndex)
        )
    }

    private func process(updateLocation: UpdateLocationHistoryRecord, result: inout HistoryFileDump) {
        result.rawLocations.append(.init(updateLocation.location))
    }
}
