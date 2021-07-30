import Foundation
import MapboxNavigationNative

public struct Parser {
    private init() {}
    
    public static func parseHistory(at path: String, with exporter: Exporter) -> String {
        exporter.start()
        let reader = HistoryReader(path: path)
        while let nextRecord = reader.next() {
            exporter.append(nextRecord)
        }
        return exporter.end()
    }
}
