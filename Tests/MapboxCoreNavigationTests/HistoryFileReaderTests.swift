import XCTest
import TestHelper
import MapboxCoreNavigation

class HistoryFileReaderTests: XCTestCase {
    
    var historyFileURL: URL {
        Fixture.bundle.url(forResource: "ag_history.pbf", withExtension: "gz")!
    }
    
    func testAsyncRead() {
        let reader = HistoryFileReader(fileUrl: historyFileURL)
        
        let expectation = XCTestExpectation(description: "Async file read should not be too long")
        try? reader.asyncRead(completion: { result in
            switch result {
            case .failure(let error):
                XCTFail("Failed to async read history file due to error: \(error.localizedDescription)")
            case .success(let dump):
                XCTAssertNotNil(dump.initialRoute)
                XCTAssertTrue(!dump.rawLocations.isEmpty)
            }
            expectation.fulfill()
        })
        
        wait(for: [expectation], timeout: 2)
    }
    
    func testSyncRead() {
        let reader = HistoryFileReader(fileUrl: historyFileURL)
        
        let dump = try? reader.syncRead()
        
        XCTAssertNotNil(dump)
        XCTAssertNotNil(dump?.initialRoute)
        XCTAssertTrue(!(dump?.rawLocations.isEmpty ?? true))
    }
    
    func testSequentialRead() {
        let reader = HistoryFileReader(fileUrl: historyFileURL)
        
        var hasInitialRoute = false
        var hasLocationUpdate = false
        while let next = try? reader.readNext() {
            switch next {
            case is HistorySetRoute:
                hasInitialRoute = true
            case is HistoryUpdateLocation:
                hasLocationUpdate = true
            default:
                break
            }
        }
        
        XCTAssertTrue(hasInitialRoute)
        XCTAssertTrue(hasLocationUpdate)
    }
}
