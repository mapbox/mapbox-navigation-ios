import Foundation

public struct HistoryFile: Codable, Identifiable {
    public var id: String { path }
    public let path: String
    public let name: String
    public let date: Date?
    public let size: UInt?
}

extension HistoryFile {
    public init(_ fileUrl: URL) {
        self.path = fileUrl.path
        self.name = fileUrl.lastPathComponent
        let fileAttr = try? FileManager.default.attributesOfItem(atPath: fileUrl.path)
        self.date = fileAttr?[.creationDate] as? Date
        self.size = fileAttr?[.size] as? UInt
    }
}
