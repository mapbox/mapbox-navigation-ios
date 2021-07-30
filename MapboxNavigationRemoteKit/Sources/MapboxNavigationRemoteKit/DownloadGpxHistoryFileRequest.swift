import Foundation

public struct DownloadGpxHistoryFileRequest: Codable {
    public init(historyFile: HistoryFile) {
        self.historyFile = historyFile
    }

    public let historyFile: HistoryFile
}

public struct DownloadGpxHistoryFileResponse: Codable {
    public init(name: String, data: Data) {
        self.name = name
        self.data = data
    }

    public let name: String
    public let data: Data
}
