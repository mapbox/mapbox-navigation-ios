
import Foundation
import SwiftCLI

class DiffCommand: Command {
    var name = "diff"
    var shortDescription: String = "Runs a comparison between 2 JSON API logs and prints detected breaking changes."
    
    @Param var oldProjectPath: String
    @Param var newProjectPath: String
    
    @Flag("-i", "--ignore", description: "Flags if only documented symbols should be checked.")
    var ignoreUndocumented: Bool
    
    @VariadicKey("-a", "--accessibility", description: "Include only entities with specified access level. May be repeated to contain mutilple values. Defaults to `public` and `open`.")
    var accessLevels: [DiffReportOptions.Accessibility]
    
    
    func execute() throws {
        guard try runApiDiff(oldApiPath: absURL(oldProjectPath),
                             newApiPath: absURL(newProjectPath)) else {
            exit(1)
        }
    }
    
    private func runApiDiff(oldApiPath: URL, newApiPath: URL) throws -> Bool {
        var options = DiffReportOptions()
        options.ignoreUndocumented = ignoreUndocumented
        if accessLevels.isEmpty {
            options.accessibilityLevels = [DiffReportOptions.Accessibility.public, DiffReportOptions.Accessibility.open]
        } else {
            options.accessibilityLevels = accessLevels
        }
        
        let diffReport = DiffReport(reportOptions: options)
        let oldApi = try readJson(at: oldApiPath)
        let newApi = try readJson(at: newApiPath)
        let report = try diffReport.generateReport(oldApi: oldApi, newApi: newApi)
        
        if report.isEmpty {
            print("No breaking changes detected!")
            return true
        } else {
            print("\n**** BREAKING CHANGES DETECTED ****")
            for (symbol, change) in report {
                print("\nBreaking changes in '\(symbol)'")
                print(change.map({ $0.toMarkdown() }).joined(separator: "\n\n"))
            }
            return false
        }
    }
    
    private func readJson(at path: URL) throws -> Any {
        let data = try Data(contentsOf: path)
        
        if !data.isEmpty {
            return try JSONSerialization.jsonObject(with: data)
        } else {
            return []
        }
    }
}
