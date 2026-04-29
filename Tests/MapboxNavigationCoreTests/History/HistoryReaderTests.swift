@testable import MapboxNavigationCore
import XCTest

final class HistoryReaderTests: XCTestCase {
    var historyFileURL: URL {
        Bundle.module.url(
            forResource: "history_replay",
            withExtension: "gz",
            subdirectory: "Fixtures"
        )!
    }

    func testAsyncRead() async {
        let readerWithUnknown = HistoryReader(fileUrl: historyFileURL)

        let dumpWithUnknown = try? await readerWithUnknown?.parse()

        XCTAssertNotNil(dumpWithUnknown)
        XCTAssertNotNil(dumpWithUnknown?.initialRoute)
        XCTAssertTrue(!(dumpWithUnknown?.rawLocations.isEmpty ?? true))
        XCTAssertTrue(dumpWithUnknown?.events.contains(where: { $0 is UnknownHistoryEvent }) ?? false)

        let cleanReader = HistoryReader(fileUrl: historyFileURL, readOptions: .omitUnknownEvents)

        let cleanDump = try? await cleanReader?.parse()

        XCTAssertNotNil(cleanDump)
        XCTAssertNotNil(cleanDump?.initialRoute)
        XCTAssertTrue(!(cleanDump?.rawLocations.isEmpty ?? true))
        XCTAssertFalse(cleanDump?.events.contains(where: { $0 is UnknownHistoryEvent }) ?? true)

        XCTAssertEqual(dumpWithUnknown?.initialRoute?.mainRoute, cleanDump?.initialRoute?.mainRoute)
        XCTAssertEqual(dumpWithUnknown?.rawLocations.map(\.coordinate), cleanDump?.rawLocations.map(\.coordinate))
        XCTAssertTrue(dumpWithUnknown?.events.count ?? 0 > cleanDump?.events.count ?? 0)
    }

    func testAsyncSequentialRead() async {
        let reader = HistoryReader(fileUrl: historyFileURL, readOptions: .omitUnknownEvents)

        var hasInitialRoute = false
        var hasLocationUpdate = false
        for await next in reader! {
            switch next {
            case is RouteAssignmentHistoryEvent:
                hasInitialRoute = true
            case is LocationUpdateHistoryEvent:
                hasLocationUpdate = true
            default:
                break
            }
        }

        XCTAssertTrue(hasInitialRoute)
        XCTAssertTrue(hasLocationUpdate)
    }
}
