import Foundation
import MapboxDirections
import Turf
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

protocol DirectionsResultsProvider {
    var directionsResults: [any DirectionsResult]? { get }
}

extension RouteResponse: DirectionsResultsProvider {
    var directionsResults: [any DirectionsResult]? { routes }
}

extension MapMatchingResponse: DirectionsResultsProvider {
    var directionsResults: [any DirectionsResult]? { matches }
}

class CodingOperation<ResponseType: Codable & DirectionsResultsProvider, OptionsType: DirectionsOptions> {
    // MARK: - Parameters

    let options: ProcessingOptions
    let credentials: Credentials

    // MARK: - Helper methods

    private func processResponse(_ decoder: JSONDecoder, from data: Data) throws -> (Data, ResponseType) {
        let result = try decoder.decode(ResponseType.self, from: data)
        let encoder = JSONEncoder()
        let data = try encoder.encode(result)
        return (data, result)
    }

    private func processOutput(
        _ data: Data,
        directionsResultsProvider: DirectionsResultsProvider? = nil
    ) throws {
        var outputText = ""

        switch options.outputFormat {
        case .text:
            outputText = String(data: data, encoding: .utf8)!

        case .json:
            if let object = try? JSONSerialization.jsonObject(with: data, options: []),
               let jsonData = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted])
            {
                outputText = String(data: jsonData, encoding: .utf8)!
            }

        case .gpx:
            var gpxText = String("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
            gpxText
                .append(
                    "\n<gpx xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns=\"http://www.topografix.com/GPX/1/1\" xsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd\" version=\"1.1\">"
                )

            if let directionsResultsProvider,
               let directionsResults = directionsResultsProvider.directionsResults
            {
                directionsResults.forEach { result in
                    let text = populateGPX(result)
                    gpxText.append(text)
                    if directionsResults.count > 1 {
                        gpxText.append("<!--Moving to next route-->")
                    }
                }
            }
            gpxText.append("\n</gpx>")
            outputText = gpxText
        }

        if let outputPath = options.outputPath {
            try outputText.write(
                toFile: NSString(string: outputPath).expandingTildeInPath,
                atomically: true,
                encoding: .utf8
            )
        } else {
            print(outputText)
        }
    }

    private func populateGPX(_ result: (any DirectionsResult)?) -> String {
        let timeInterval: TimeInterval = 1
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = .withInternetDateTime
        var time = Date()
        var text = ""
        var coordinates: [LocationCoordinate2D?] = []

        guard let result else { return "" }
        coordinates = interpolate(
            shape: result.shape,
            expectedTravelTime: result.expectedTravelTime,
            distance: result.distance,
            timeInterval: timeInterval
        )

        for coord in coordinates {
            guard let lat = coord?.latitude, let lon = coord?.longitude else { continue }
            text.append("\n<wpt lat=\"\(lat)\" lon=\"\(lon)\">")
            text.append("\n\t<time> \(dateFormatter.string(from: time)) </time>")
            text.append("\n</wpt>")
            time.addTimeInterval(timeInterval)
        }
        return text
    }

    private func interpolate(
        shape: LineString?,
        expectedTravelTime: TimeInterval,
        distance: LocationDistance,
        timeInterval: TimeInterval
    ) -> [LocationCoordinate2D?] {
        guard expectedTravelTime > 0, let polyline = shape,
              let firstCoordinate = polyline.coordinates.first,
              let lastCoordinate = polyline.coordinates.last else { return [] }

        var distanceAway: LocationDistance = 0
        let distancePerTick = distance / expectedTravelTime
        var interpolatedCoordinates = [firstCoordinate]
        while distanceAway <= distance {
            if let nextCoordinate = polyline.coordinateFromStart(distance: distanceAway) {
                interpolatedCoordinates.append(nextCoordinate)
            }
            distanceAway += distancePerTick * timeInterval
        }
        interpolatedCoordinates.append(lastCoordinate)
        return interpolatedCoordinates
    }

    private func response(fetching directionsOptions: OptionsType) -> (Data) {
        let directions = Directions(credentials: credentials)
        let url = directions.url(forCalculating: directionsOptions)
        return response(fetching: url)
    }

    private func response(fetching url: URL) -> Data {
        let semaphore = DispatchSemaphore(value: 0)

        var responseData: Data!

        let urlSession = URLSession(configuration: .ephemeral)

        let task = urlSession.dataTask(with: url) { data, _, error in
            guard let data, error == nil else {
                fatalError(error!.localizedDescription)
            }

            responseData = data
            semaphore.signal()
        }

        task.resume()
        semaphore.wait()

        return responseData
    }

    init(options: ProcessingOptions, credentials: Credentials) {
        self.options = options
        self.credentials = credentials
    }

    // MARK: - Command implementation

    func execute() throws {
        let directions: Directions
        let directionsOptions: OptionsType
        let requestURL: URL
        if FileManager.default.fileExists(atPath: (options.config as NSString).expandingTildeInPath) {
            // Assume the file is a configuration JSON file. Convert it to an options object.
            let configData = FileManager.default.contents(atPath: (options.config as NSString).expandingTildeInPath)!
            let decoder = JSONDecoder()
            directions = Directions(credentials: credentials)
            directionsOptions = try decoder.decode(OptionsType.self, from: configData)
        } else if let url = URL(string: options.config) {
            // Try to convert the URL to an options object.
            if let parsedOptions = (RouteOptions(url: url) ?? MatchOptions(url: url)) as? OptionsType {
                directionsOptions = parsedOptions
            } else {
                fatalError("Configuration is not a valid Mapbox Directions API or Mapbox Map Matching API request URL.")
            }

            // Get credentials from the request URL but fall back to the environment.
            var urlWithAccessToken = URLComponents(string: url.absoluteString)!
            urlWithAccessToken.queryItems = (urlWithAccessToken.queryItems ?? []) + [.init(
                name: "access_token",
                value: credentials.accessToken
            )]
            let credentials = Credentials(requestURL: urlWithAccessToken.url!)

            directions = Directions(credentials: credentials)
        } else {
            fatalError("Configuration is not a valid JSON configuration file or request URL.")
        }

        let input: Data
        if let inputPath = options.inputPath {
            input = FileManager.default.contents(atPath: NSString(string: inputPath).expandingTildeInPath)!
        } else {
            requestURL = directions.url(forCalculating: directionsOptions)
            let response = response(fetching: requestURL)
            input = response
        }

        let decoder = JSONDecoder()
        decoder.userInfo = [
            .options: directionsOptions,
            .credentials: credentials,
        ]

        let (data, directionsResultsProvider) = try processResponse(decoder, from: input)

        try processOutput(data, directionsResultsProvider: directionsResultsProvider)
    }
}
