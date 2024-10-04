import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(CoreLocation)
import CoreLocation
#endif
import Turf

/// Computes areas that are reachable within a specified amount of time or distance from a location, and returns the
/// reachable regions as contours of polygons or lines that you can display on a map.
open class Isochrones: @unchecked Sendable {
    /// A tuple type representing the isochrone session that was generated from the request.
    /// - Parameter options: A ``IsochroneOptions`` object representing the request parameter options.
    /// - Parameter credentials: A object containing the credentials used to make the request.
    public typealias Session = (options: IsochroneOptions, credentials: Credentials)

    /// A closure (block) to be called when a isochrone request is complete.
    ///
    /// - Parameter result: A `Result` enum that represents the `FeatureCollection` if the request returned
    /// successfully, or the error if it did not.
    public typealias IsochroneCompletionHandler = @MainActor @Sendable (
        _ result: Result<FeatureCollection, IsochroneError>
    ) -> Void

    // MARK: Creating an Isochrones Object

    /// The Authorization & Authentication credentials that are used for this service.
    ///
    /// If nothing is provided, the default behavior is to read credential values from the developer's Info.plist.
    public let credentials: Credentials
    private let urlSession: URLSession
    private let processingQueue: DispatchQueue

    /// The shared isochrones object.
    ///
    /// To use this object, a Mapbox [access token](https://docs.mapbox.com/help/glossary/access-token/) should be
    /// specified in the `MBXAccessToken` key in the main application bundle’s Info.plist.
    public static let shared: Isochrones = .init()

    /// Creates a new instance of Isochrones object.
    /// - Parameters:
    ///   - credentials: Credentials that will be used to make API requests to Mapbox Isochrone API.
    ///   - urlSession: URLSession that will be used to submit API requests to Mapbox Isochrone API.
    ///   - processingQueue: A DispatchQueue that will be used for CPU intensive work.
    public init(
        credentials: Credentials = .init(),
        urlSession: URLSession = .shared,
        processingQueue: DispatchQueue = .global(qos: .userInitiated)
    ) {
        self.credentials = credentials
        self.urlSession = urlSession
        self.processingQueue = processingQueue
    }

    /// Begins asynchronously calculating isochrone contours using the given options and delivers the results to a
    /// closure.
    /// This method retrieves the contours asynchronously from the [Mapbox Isochrone
    /// API](https://docs.mapbox.com/api/navigation/isochrone/) over a network connection. If a connection error or
    /// server error occurs, details about the error are passed into the given completion handler in lieu of the
    /// contours.
    ///
    /// Contours may be displayed atop a [Mapbox map](https://www.mapbox.com/maps/).
    /// - Parameters:
    ///   - options: An ``IsochroneOptions`` object specifying the requirements for the resulting contours.
    ///   - completionHandler: The closure (block) to call with the resulting contours. This closure is executed on the
    /// application’s main thread.
    /// - Returns: The data task used to perform the HTTP request. If, while waiting for the completion handler to
    /// execute, you no longer want the resulting contours, cancel this task.
    @discardableResult
    open func calculate(
        _ options: IsochroneOptions,
        completionHandler: @escaping IsochroneCompletionHandler
    ) -> URLSessionDataTask {
        let request = urlRequest(forCalculating: options)
        let callCompletion = { @Sendable (_ result: Result<FeatureCollection, IsochroneError>) in
            _ = Task { @MainActor in
                completionHandler(result)
            }
        }
        let requestTask = urlSession.dataTask(with: request) { possibleData, possibleResponse, possibleError in
            if let urlError = possibleError as? URLError {
                callCompletion(.failure(.network(urlError)))
                return
            }

            guard let response = possibleResponse, ["application/json", "text/html"].contains(response.mimeType) else {
                callCompletion(.failure(.invalidResponse(possibleResponse)))
                return
            }

            guard let data = possibleData else {
                callCompletion(.failure(.noData))
                return
            }

            self.processingQueue.async {
                do {
                    let decoder = JSONDecoder()

                    guard let disposition = try? decoder.decode(ResponseDisposition.self, from: data) else {
                        let apiError = IsochroneError(
                            code: nil,
                            message: nil,
                            response: possibleResponse,
                            underlyingError: possibleError
                        )

                        callCompletion(.failure(apiError))
                        return
                    }

                    guard (disposition.code == nil && disposition.message == nil) || disposition.code == "Ok" else {
                        let apiError = IsochroneError(
                            code: disposition.code,
                            message: disposition.message,
                            response: response,
                            underlyingError: possibleError
                        )
                        callCompletion(.failure(apiError))
                        return
                    }

                    let result = try decoder.decode(FeatureCollection.self, from: data)

                    callCompletion(.success(result))
                } catch {
                    let bailError = IsochroneError(code: nil, message: nil, response: response, underlyingError: error)
                    callCompletion(.failure(bailError))
                }
            }
        }
        requestTask.priority = 1
        requestTask.resume()

        return requestTask
    }

    // MARK: Request URL Preparation

    /// The GET HTTP URL used to fetch the contours from the API.
    ///
    /// - Parameter options: An ``IsochroneOptions`` object specifying the requirements for the resulting contours.
    /// - Returns: The URL to send the request to.
    open func url(forCalculating options: IsochroneOptions) -> URL {
        var params = options.urlQueryItems
        params.append(URLQueryItem(name: "access_token", value: credentials.accessToken))

        let unparameterizedURL = URL(path: options.path, host: credentials.host)
        var components = URLComponents(url: unparameterizedURL, resolvingAgainstBaseURL: true)!
        components.queryItems = params
        return components.url!
    }

    /// The HTTP request used to fetch the contours from the API.
    ///
    /// - Parameter options: A ``IsochroneOptions`` object specifying the requirements for the resulting routes.
    /// - Returns: A GET HTTP request to calculate the specified options.
    open func urlRequest(forCalculating options: IsochroneOptions) -> URLRequest {
        let getURL = url(forCalculating: options)
        var request = URLRequest(url: getURL)
        request.setupUserAgentString()
        return request
    }
}

@available(*, unavailable)
extension Isochrones: @unchecked Sendable {}
