import Foundation

public struct HistoryFilesRequest: Codable {
    public init() {}
}

public struct HistoryFilesResponse: Codable {
    public init(files: [HistoryFile]) {
        self.files = files
    }

    public let files: [HistoryFile]
}
