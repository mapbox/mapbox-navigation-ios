
import Foundation
import SwiftCLI

class LogCommand: Command {
    var name = "log"
    var shortDescription: String = "Parses provided project and logs it's API structure in JSON format."
    
    @Param var projectPath: String
    @Param var outputPath: String
    @CollectedParam var sourcekittenArgs: [String]
    
    func execute() throws {        
        guard let log = try runApiLog(apiFolder: projectPath,
                                      args: sourcekittenArgs) else {
            print("Decoding 'sourcekitten' output failed.")
            exit(1)
        }
        let outputURL = absURL(outputPath)
        try FileManager.default.createDirectory(at: outputURL.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try log.write(to: outputURL,
                      atomically: true,
                      encoding: .utf8)
    }
    
    private func runApiLog(apiFolder: String, args: [String]) throws -> String? {
        print("Running API Logging... ")
        guard let APIDoc = runSourcekitten(apiFolder: apiFolder,
                                           args: args) else {
                                            exit(1)
        }
        
        return String(data: APIDoc, encoding: .utf8)
    }
    
    private func runSourcekitten(apiFolder: String, args: [String]) -> Data? {
        var result = Data()
        let task = Process()
        task.launchPath = "/usr/local/bin/sourcekitten"
        task.currentDirectoryPath = apiFolder
        task.arguments = args
        
        let standardOutput = Pipe()
        let standardError = Pipe()
        let outputHandle = standardOutput.fileHandleForReading
        let errorHandle = standardError.fileHandleForReading
        outputHandle.waitForDataInBackgroundAndNotify()
        errorHandle.waitForDataInBackgroundAndNotify()
        outputHandle.readabilityHandler = { pipe in
            result.append(pipe.availableData)
        }
        errorHandle.readabilityHandler = { pipe in
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
            return result
        } else {
            print("Sourcekitten failed.")
            return nil
        }
    }
}
