
import Foundation

struct ApiLog {
    
    static func runApiLog(apiFolder: String, args: [String]) throws -> String? {
        print("Running API Logging... ")
        guard let APIDoc = runSourcekitten(apiFolder: apiFolder,
                                           args: args) else {
                                            exit(1)
        }
        
        return String(data: APIDoc, encoding: .utf8)
    }
    
    static private func runSourcekitten(apiFolder: String, args: [String]) -> Data? {
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
