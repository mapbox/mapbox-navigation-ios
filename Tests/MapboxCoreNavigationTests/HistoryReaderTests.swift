import XCTest
import TestHelper
import MapboxCoreNavigation

class HistoryReaderTests: XCTestCase {
    
    var historyFileURL: URL {
        Fixture.bundle.url(forResource: "ag_history.pbf", withExtension: "gz")!
    }
    
    func testSyncRead() {
        let readerWithUnknown = HistoryReader(fileUrl: historyFileURL)
        
        let dumpWithUnknown = try? readerWithUnknown?.parse()
        
        XCTAssertNotNil(dumpWithUnknown)
        XCTAssertNotNil(dumpWithUnknown?.initialRoute)
        XCTAssertTrue(!(dumpWithUnknown?.rawLocations.isEmpty ?? true))
        XCTAssertTrue(dumpWithUnknown?.events.contains(where: { $0 is UnknownHistoryEvent }) ?? false)
        
        let cleanReader = HistoryReader(fileUrl: historyFileURL, readOptions: .omitUnknownEvents)
        
        let cleanDump = try? cleanReader?.parse()
        
        XCTAssertNotNil(cleanDump)
        XCTAssertNotNil(cleanDump?.initialRoute)
        XCTAssertTrue(!(cleanDump?.rawLocations.isEmpty ?? true))
        XCTAssertFalse(cleanDump?.events.contains(where: { $0 is UnknownHistoryEvent }) ?? true)
        
        XCTAssertEqual(dumpWithUnknown?.initialRoute?.currentRoute, cleanDump?.initialRoute?.currentRoute)
        XCTAssertEqual(dumpWithUnknown?.rawLocations.map(\.coordinate), cleanDump?.rawLocations.map(\.coordinate))
        XCTAssertTrue(dumpWithUnknown?.events.count ?? 0 > cleanDump?.events.count ?? 0)
    }
    
    func testSequentialRead() {
        let reader = HistoryReader(fileUrl: historyFileURL, readOptions: .omitUnknownEvents)
        
        var hasInitialRoute = false
        var hasLocationUpdate = false
        for next in reader! {
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
