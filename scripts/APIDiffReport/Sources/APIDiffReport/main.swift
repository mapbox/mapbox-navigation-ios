import Foundation
import SwiftCLI

func absURL ( _ path: String ) -> URL {
    return URL(fileURLWithPath: (path as NSString).expandingTildeInPath)
}

CLI(name: "APIDiffReport",
    description: "A tool to detect Public API breaking changes",
    commands: [LogCommand(), DiffCommand()]).goAndExit()
