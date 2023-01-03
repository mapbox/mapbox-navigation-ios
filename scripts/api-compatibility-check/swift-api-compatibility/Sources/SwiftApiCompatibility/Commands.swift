import ArgumentParser
import SwiftApiCompatibilityKit
import Foundation

@main
struct Main: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "swift-api-compatibility",
        abstract: "A tool to check the API compatibility of Swift libraries.",
        subcommands: [
            ParseBreakingChangesReport.self,
        ]
    )
}

struct ParseBreakingChangesReport: ParsableCommand {
    static var configuration = CommandConfiguration(
        commandName: "parse-report",
        abstract: "Parses output from 'swift-api-digester -diagnose-sdk' and pretty format it"
    )

    @Option(help: "The format of the parsed output")
    var outputFormat: OutputFormat = .gitHubMarkdown

    @Argument(help: "The name of the module report is generated for.")
    var moduleName: String

    @Argument(help: "The output from 'swift-api-digester -diagnose-sdk' invocation")
    var swiftDigesterOutput: String

    func run() throws {
        let report = try BreakingChangesReport(moduleName: moduleName, swiftApiDigesterOutput: swiftDigesterOutput)
        let output = report.formatted(to: outputFormat)
        FileHandle.standardOutput.write(Data(output.utf8))        
    }
}

extension OutputFormat: ExpressibleByArgument {}
