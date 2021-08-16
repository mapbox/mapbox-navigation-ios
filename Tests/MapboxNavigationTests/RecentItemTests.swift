import XCTest
import CoreLocation
import TestHelper
@testable import MapboxNavigation

class RecentItemTests: TestCase {
    
    func testRecentItemMatching() {
        let navigationGeocodedPlacemark = NavigationGeocodedPlacemark(title: "title",
                                                                      subtitle: "subtitle",
                                                                      location: nil,
                                                                      routableLocations: nil)
        
        let recentItem = RecentItem(navigationGeocodedPlacemark)
        
        XCTAssertFalse(recentItem.matches("test"), "Match should not be found.")
        XCTAssertTrue(recentItem.matches("title"), "Match should be found.")
    }
    
    func testRecentItemsSavingAndLoading() {
        XCTAssertEqual(RecentItem.loadDefaults().count, 0, "There should be no recent items.")
        
        let firstNavigationGeocodedPlacemark = NavigationGeocodedPlacemark(title: "San Francisco",
                                                                           subtitle: "CA",
                                                                           location: CLLocation(latitude: 37.772898, longitude: -122.411765),
                                                                           routableLocations: nil)
        var firstRecentItem = RecentItem(firstNavigationGeocodedPlacemark)
        // `RecentItem.loadDefaults()` loads the most recent items first. `RecentItem.timestamp` is
        // changed here to verify this. This means that `secondRecentItem` should be the first one
        // in returned list.
        firstRecentItem.timestamp = Date().addingTimeInterval(10.0)
        var recentItems = [firstRecentItem]
        
        XCTAssertTrue(recentItems.save(), "Saving should be successful.")
        XCTAssertEqual(RecentItem.loadDefaults().count, 1, "There should be one recent item.")
        
        let secondNavigationGeocodedPlacemark = NavigationGeocodedPlacemark(title: "Seattle",
                                                                            subtitle: "WA",
                                                                            location: CLLocation(latitude: 47.605215, longitude: -122.33029),
                                                                            routableLocations: nil)
        let secondRecentItem = RecentItem(secondNavigationGeocodedPlacemark)
        recentItems.append(secondRecentItem)
        XCTAssertTrue(recentItems.save(), "Saving should be successful.")
        
        let savedRecentItems = RecentItem.loadDefaults()
        if savedRecentItems.count != 2 {
            XCTFail("There should be two recent items.")
            return
        }
        
        XCTAssertEqual(savedRecentItems[0], firstRecentItem, "Recent item, with modified timestamp should be the first one in a list.")
        XCTAssertEqual(savedRecentItems[1], secondRecentItem, "Recent item, with no modifications to timestamp should be the second one in a list.")
        
        addTeardownBlock {
            do {
                guard let recentItemsPathURL = RecentItem.recentItemsPathURL else {
                    XCTFail("File URL, where recent items are saved should be available.")
                    return
                }
                try FileManager.default.removeItem(at: recentItemsPathURL)
            } catch {
                XCTFail("Failed to remove file with recent items with error: \(error.localizedDescription)")
            }
        }
    }
    
    func testRecentItemsAddingAndRemoving() {
        let firstTitle = "San Francisco"
        let firstNavigationGeocodedPlacemark = NavigationGeocodedPlacemark(title: firstTitle,
                                                                           subtitle: "CA",
                                                                           location: CLLocation(latitude: 37.772898, longitude: -122.411765),
                                                                           routableLocations: nil)
        let firstRecentItem = RecentItem(firstNavigationGeocodedPlacemark)
        
        let secondTitle = "Seattle"
        let secondNavigationGeocodedPlacemark = NavigationGeocodedPlacemark(title: secondTitle,
                                                                            subtitle: "WA",
                                                                            location: CLLocation(latitude: 47.605215, longitude: -122.33029),
                                                                            routableLocations: nil)
        let secondRecentItem = RecentItem(secondNavigationGeocodedPlacemark)
        
        var recentItems: [RecentItem] = []
        recentItems.add(firstRecentItem)
        XCTAssertEqual(recentItems.count, 1, "There should be one element in recent items array.")
        
        recentItems.add(firstRecentItem)
        XCTAssertEqual(recentItems.count, 1, "There should be one element in recent items array, because previously added recent item has to be updated.")
        
        guard let firstRecentItemWithUpdatedTimestamp = recentItems.first else {
            XCTFail("Recent item was not found.")
            return
        }
        
        recentItems.remove(firstRecentItemWithUpdatedTimestamp)
        XCTAssertEqual(recentItems.count, 0, "After removal there should be no elements in array.")
        
        recentItems.add(firstRecentItem)
        recentItems.add(secondRecentItem)
        XCTAssertEqual(recentItems.count, 2, "There should two elements in recent items array.")
        XCTAssertEqual(recentItems[0].navigationGeocodedPlacemark.title, secondTitle, "Titles should be similar.")
        XCTAssertEqual(recentItems[1].navigationGeocodedPlacemark.title, firstTitle, "Titles should be similar.")
    }
}
