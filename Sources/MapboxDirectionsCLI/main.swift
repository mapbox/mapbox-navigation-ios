#!/usr/bin/swift

import ArgumentParser
import Foundation
import MapboxDirections

struct ProcessingOptions: ParsableArguments {
    @Option(
        name: [.short, .customLong("input")],
        help: "[Optional] Filepath to the input JSON. If no filepath provided - will fall back to Directions API request using locations in config file."
    )
    var inputPath: String?

    @Argument(
        help: "Path to a JSON file containing serialized RouteOptions or MatchOptions properties, or the full URL of a Mapbox Directions API or Mapbox Map Matching API request."
    )
    var config: String

    @Option(
        name: [.short, .customLong("output")],
        help: "[Optional] Output filepath to save the conversion result. If no filepath provided - will output to the shell."
    )
    var outputPath: String?

    @Option(
        name: [.customShort("f"), .customLong("format")],
        help: "Output format. Supports `text`, `json`, and `gpx` formats."
    )
    var outputFormat: OutputFormat = .text

    enum OutputFormat: String, ExpressibleByArgument, CaseIterable {
        case text
        case json
        case gpx
    }
}

struct Command: ParsableCommand {
    static var credentials: Credentials {
        get throws {
            guard let accessToken = ProcessInfo.processInfo.environment["MAPBOX_ACCESS_TOKEN"] ??
                UserDefaults.standard.string(forKey: "MBXAccessToken")
            else {
                throw ValidationError(
                    "A Mapbox access token is required. Go to <https://account.mapbox.com/access-tokens/>, then set the MAPBOX_ACCESS_TOKEN environment variable to your access token."
                )
            }

            let hostURL: URL? = if let host = ProcessInfo.processInfo.environment["MAPBOX_HOST"] ??
                UserDefaults.standard.string(forKey: "MGLMapboxAPIBaseURL")
            {
                URL(string: host)
            } else {
                nil
            }

            return Credentials(accessToken: accessToken, host: hostURL)
        }
    }

    static var configuration = CommandConfiguration(
        commandName: "mapbox-directions-swift",
        abstract: "'mapbox-directions-swift' is a command line tool, designed to round-trip an arbitrary, JSON-formatted Directions or Map Matching API response through model objects and back to JSON.",
        subcommands: [Match.self, Route.self]
    )

    fileprivate static func validateInput(_ options: ProcessingOptions) throws {
        if !FileManager.default.fileExists(atPath: (options.config as NSString).expandingTildeInPath),
           URL(string: options.config) == nil
        {
            throw ValidationError("Configuration is a nonexistent file or invalid request URL: \(options.config)")
        }
    }
}

extension Command {
    struct Match: ParsableCommand {
        static var configuration =
            CommandConfiguration(
                commandName: "match",
                abstract: "Command to process Map Matching Data."
            )

        @ArgumentParser.OptionGroup var options: ProcessingOptions

        mutating func validate() throws {
            try Command.validateInput(options)
        }

        mutating func run() throws {
            try CodingOperation<MapMatchingResponse, MatchOptions>(options: options, credentials: credentials).execute()
        }
    }
}

extension Command {
    struct Route: ParsableCommand {
        static var configuration =
            CommandConfiguration(
                commandName: "route",
                abstract: "Command to process Routing Data."
            )

        @ArgumentParser.OptionGroup var options: ProcessingOptions

        mutating func validate() throws {
            try Command.validateInput(options)
        }

        mutating func run() throws {
            try CodingOperation<RouteResponse, RouteOptions>(options: options, credentials: credentials).execute()
        }
    }
}

Command.main()
