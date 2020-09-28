import Foundation


if ProcessInfo.processInfo.arguments.count < 2 {
    print("usage: APIDiffReport <old api project folder> <new (updated) api project folder> [forwarding sourcekitten args]")
    exit(1)
}

func readJson(at path: String) throws -> Any {
    let url = URL(fileURLWithPath: path)
    let data = try Data(contentsOf: url)
    
    if !data.isEmpty {
        return try JSONSerialization.jsonObject(with: data)
    } else {
        return []
    }
}

func runSourcekitten(apiFolder: String, args: [String]) -> Data? {
//    let resultFileURL = NSURL.fileURL(withPathComponents: [NSTemporaryDirectory(), NSUUID().uuidString])
    // sourcekitten doc --module-name test -- -sdk iphonesimulator -destination 'platform=iOS Simulator,OS=13.3,name=iPhone 8 Plus' -project ../updated/test.xcodeproj -scheme test clean build > ../updated.txt
    let task = Process()
    task.launchPath = "/usr/local/bin/sourcekitten"
    task.currentDirectoryPath = apiFolder
    task.arguments = args
    
    let standardOutput = Pipe()
    let standardError = Pipe()
    let outputHandle = standardError.fileHandleForReading
    outputHandle.waitForDataInBackgroundAndNotify()
    outputHandle.readabilityHandler = { pipe in
        guard let currentOutput = String(data: pipe.availableData, encoding: .utf8) else {
            print("Error decoding output data: \(pipe.availableData)")
            return
        }
        
        guard !currentOutput.isEmpty else {
            return
        }
        DispatchQueue.main.async {
            print(currentOutput)
        }
    }
    
    task.standardOutput = standardOutput
    task.standardError = standardError
    task.launch()
    task.waitUntilExit()

    if task.terminationStatus == 0 {
        print("Sourcekitten succeeded.")
        return standardOutput.fileHandleForReading.readDataToEndOfFile()
    } else {
        print("Sourcekitten failed.")
        return nil
    }
}

let oldApiFolder = ProcessInfo.processInfo.arguments[1]
let newApiFolder = ProcessInfo.processInfo.arguments[2]
var sourcekittenArgs = Array<String>()

if ProcessInfo.processInfo.arguments.count > 2 {
    sourcekittenArgs = Array(ProcessInfo.processInfo.arguments.suffix(from: 3))
}

print("Running 'Old API' Sourcekitten... ")
guard let oldAPIDoc = runSourcekitten(apiFolder: oldApiFolder,
                                      args: sourcekittenArgs) else {
    exit(1)
}

print("Running 'New API' Sourcekitten... ")
guard let newAPIDoc = runSourcekitten(apiFolder: newApiFolder,
                                      args: sourcekittenArgs) else {
    exit(1)
}

let oldApi = try JSONSerialization.jsonObject(with: oldAPIDoc)
let newApi = try JSONSerialization.jsonObject(with: newAPIDoc)

let report = try diffreport(oldApi: oldApi, newApi: newApi)

if report.isEmpty {
    print("No breaking changes detected!")
} else {
    print("\n**** BREAKING CHANGES DETECTED ****")
    for (symbol, change) in report {
        print("\nBreaking changes in '\(symbol)'")
        print(change.map({ $0.toMarkdown() }).joined(separator: "\n\n"))
    }
    exit(2)
}


