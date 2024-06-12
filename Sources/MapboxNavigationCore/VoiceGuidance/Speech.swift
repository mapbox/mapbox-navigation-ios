import _MapboxNavigationHelpers
import Foundation

/// A `SpeechSynthesizer` object converts text into spoken audio. Unlike `AVSpeechSynthesizer`, a `SpeechSynthesizer`
/// object produces audio by sending an HTTP request to the Mapbox Voice API, which produces more natural-sounding audio
/// in various languages. With a speech synthesizer object, you can asynchronously generate audio data based on the
/// ``SpeechOptions`` object you provide, or you can get the URL used to make this request.
///
/// Use `AVAudioPlayer` to play the audio that a speech synthesizer object produces.
struct SpeechSynthesizer: Sendable {
    private let apiConfiguration: ApiConfiguration
    private let skuTokenProvider: SkuTokenProvider
    private let urlSession: URLSession

    // MARK: Creating a Speech Object

    init(
        apiConfiguration: ApiConfiguration,
        skuTokenProvider: SkuTokenProvider,
        urlSession: URLSession = .shared
    ) {
        self.apiConfiguration = apiConfiguration
        self.skuTokenProvider = skuTokenProvider
        self.urlSession = urlSession
    }

    // MARK: Getting Speech

    @discardableResult
    /// Asynchronously fetches the audio file.
    /// This method retrieves the audio asynchronously over a network connection. If a connection error or server error
    /// occurs, details about the error are passed into the given completion handler in lieu of the audio file.
    /// - Parameter options: A ``SpeechOptions`` object specifying the requirements for the resulting audio file.
    /// - Returns: The audio data.
    func audioData(with options: SpeechOptions) async throws -> Data {
        try await data(with: url(forSynthesizing: options))
    }

    /// Returns a URL session task for the given URL that will run the given closures on completion or error.
    /// - Parameter url: The URL to request.
    /// - Returns: ``SpeechErrorApiError``
    private func data(
        with url: URL
    ) async throws -> Data {
        var request = URLRequest(url: url)
        request.setNavigationUXUserAgent()

        do {
            let (data, response) = try await urlSession.data(for: request)
            try validateResponse(response, data: data)
            return data
        } catch let error as SpeechErrorApiError {
            throw error
        } catch let urlError as URLError {
            throw SpeechErrorApiError.transportError(underlying: urlError)
        } catch {
            throw SpeechErrorApiError.unknownError(underlying: error)
        }
    }

    /// The HTTP URL used to fetch audio from the API.
    private func url(forSynthesizing options: SpeechOptions) -> URL {
        var params = options.params

        params.append(apiConfiguration.accessTokenUrlQueryItem())

        if let skuToken = skuTokenProvider.skuToken() {
            params += [URLQueryItem(name: "sku", value: skuToken)]
        }

        let unparameterizedURL = URL(string: options.path, relativeTo: apiConfiguration.endPoint)!
        var components = URLComponents(url: unparameterizedURL, resolvingAgainstBaseURL: true)!
        components.queryItems = params
        return components.url!
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard response.mimeType == "application/json" else { return }

        let decoder = JSONDecoder()
        let serverErrorResponse = try decoder.decode(ServerErrorResponse.self, from: data)
        if serverErrorResponse.code == "Ok" || (serverErrorResponse.code == nil && serverErrorResponse.message == nil) {
            return
        }
        try Self.parserServerError(
            response: response,
            serverErrorResponse: serverErrorResponse
        )
    }

    /// Returns an error that supplements the given underlying error with additional information from the an HTTP
    /// response’s body or headers.
    static func parserServerError(
        response: URLResponse,
        serverErrorResponse: ServerErrorResponse
    ) throws {
        guard let response = response as? HTTPURLResponse else {
            throw SpeechErrorApiError.serverError(response, serverErrorResponse)
        }

        switch response.statusCode {
        case 429:
            throw SpeechErrorApiError.rateLimited(
                rateLimitInterval: response.rateLimitInterval,
                rateLimit: response.rateLimit,
                resetTime: response.rateLimitResetTime
            )
        default:
            throw SpeechErrorApiError.serverError(response, serverErrorResponse)
        }
    }
}

enum SpeechErrorApiError: LocalizedError {
    case rateLimited(rateLimitInterval: TimeInterval?, rateLimit: UInt?, resetTime: Date?)
    case transportError(underlying: URLError)
    case unknownError(underlying: Error)
    case serverError(URLResponse, ServerErrorResponse)

    var failureReason: String? {
        switch self {
        case .transportError(underlying: let urlError):
            return urlError.userInfo[NSLocalizedFailureReasonErrorKey] as? String
        case .rateLimited(rateLimitInterval: let interval, rateLimit: let limit, _):
            let intervalFormatter = DateComponentsFormatter()
            intervalFormatter.unitsStyle = .full
            guard let interval, let limit else {
                return "Too many requests."
            }
            let formattedInterval = intervalFormatter.string(from: interval) ?? "\(interval) seconds"
            let formattedCount = NumberFormatter.localizedString(from: NSNumber(value: limit), number: .decimal)
            return "More than \(formattedCount) requests have been made with this access token within a period of \(formattedInterval)."
        case .serverError(let response, let serverResponse):
            if let serverMessage = serverResponse.message {
                return serverMessage
            } else if let httpResponse = response as? HTTPURLResponse {
                return HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode)
            } else if let code = serverResponse.code,
                      let serverStatusCode = Int(code)
            {
                return HTTPURLResponse.localizedString(forStatusCode: serverStatusCode)
            } else {
                return "Server error"
            }
        case .unknownError(underlying: let error as NSError):
            return error.userInfo[NSLocalizedFailureReasonErrorKey] as? String
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .transportError(underlying: let urlError):
            return urlError.userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String
        case .rateLimited(rateLimitInterval: _, rateLimit: _, resetTime: let rolloverTime):
            guard let rolloverTime else {
                return nil
            }
            let formattedDate: String = DateFormatter.localizedString(
                from: rolloverTime,
                dateStyle: .long,
                timeStyle: .long
            )
            return "Wait until \(formattedDate) before retrying."
        case .serverError:
            return nil
        case .unknownError(underlying: let error as NSError):
            return error.userInfo[NSLocalizedRecoverySuggestionErrorKey] as? String
        }
    }
}

extension HTTPURLResponse {
    var rateLimit: UInt? {
        guard let limit = allHeaderFields["X-Rate-Limit-Limit"] as? String else {
            return nil
        }
        return UInt(limit)
    }

    var rateLimitInterval: TimeInterval? {
        guard let interval = allHeaderFields["X-Rate-Limit-Interval"] as? String else {
            return nil
        }
        return TimeInterval(interval)
    }

    var rateLimitResetTime: Date? {
        guard let resetTime = allHeaderFields["X-Rate-Limit-Reset"] as? String else {
            return nil
        }
        guard let resetTimeNumber = Double(resetTime) else {
            return nil
        }
        return Date(timeIntervalSince1970: resetTimeNumber)
    }
}

struct ServerErrorResponse: Decodable {
    let code: String?
    let message: String?
}
