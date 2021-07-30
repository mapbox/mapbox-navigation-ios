import Foundation
import MapboxNavigationNative

public protocol Exporter {
    func start()
    func append(_ record: HistoryRecord)
    func end() -> String
}
