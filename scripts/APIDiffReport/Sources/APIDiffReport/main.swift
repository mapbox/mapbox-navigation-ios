import Foundation


func printUsage() {
    print("Usage:")
    print("    log <api project folder> <output file path> [forwarding sourcekitten args]")
    print("        - Parses provided project and logs it's API structure in JSON format.")
    print("    diff <old api log file path> <new api log file>")
    print("        - Runs a comparison between 2 JSON API logs and prints detected breaking changes.")
}

func absURL ( _ path: String ) -> URL {
    // some methods cannot correctly expand '~' in a path, so we'll do it manually
    let homeDirectory = URL(fileURLWithPath: NSHomeDirectory())
    guard path != "~" else {
        return homeDirectory
    }
    guard path.hasPrefix("~/") else { return URL(fileURLWithPath: path)  }

    var relativePath = path
    relativePath.removeFirst(2)
    return URL(string: relativePath,
               relativeTo: homeDirectory) ?? homeDirectory
}

guard ProcessInfo.processInfo.arguments.count > 2 else {
    printUsage()
    exit(1)
}

switch ProcessInfo.processInfo.arguments[1] {
case "log":
    guard ProcessInfo.processInfo.arguments.count > 3 else {
        printUsage()
        exit(1)
    }
    
    let apiFolder = ProcessInfo.processInfo.arguments[2]
    let outputFile = ProcessInfo.processInfo.arguments[3]
    var sourcekittenArgs = Array<String>()
    if ProcessInfo.processInfo.arguments.count > 4 {
        sourcekittenArgs = Array(ProcessInfo.processInfo.arguments.suffix(from: 4))
    }
    
    guard let log = try ApiLog.runApiLog(apiFolder: apiFolder, args: sourcekittenArgs) else {
        print("Decoding 'sourcekitten' output failed.")
        exit(1)
    }
    let outputURL = absURL(outputFile)
    try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(),
                                            withIntermediateDirectories: true)
    try log.write(to: outputURL,
                  atomically: true,
                  encoding: .utf8)
case "diff":
    let oldApi = ProcessInfo.processInfo.arguments[2]
    let newApi = ProcessInfo.processInfo.arguments[3]
    
    guard try ApiDiff.runApiDiff(oldApiPath: absURL(oldApi), newApiPath: absURL(newApi)) else {
        exit(1)
    }
default:
    printUsage()
    exit(1)
}
