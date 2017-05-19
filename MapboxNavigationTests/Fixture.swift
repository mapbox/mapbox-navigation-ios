import XCTest
import Foundation

internal class Fixture {
    internal class func stringFromFileNamed(name: String) -> String {
        guard let path = Bundle(for: self).path(forResource: name, ofType: "json") else {
            XCTAssert(false, "Fixture \(name) not found.")
            return ""
        }
        do {
            return try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            XCTAssert(false, "Unable to decode fixture at \(path): \(error).")
            return ""
        }
    }
    
    internal class func JSONFromFileNamed(name: String) -> [String: Any] {
        guard let path = Bundle(for: self).path(forResource: name, ofType: "json") else {
            XCTAssert(false, "Fixture \(name) not found.")
            return [:]
        }
        guard let data = NSData(contentsOfFile: path) as Data? else {
            XCTAssert(false, "No data found at \(path).")
            return [:]
        }
        do {
            return try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
        } catch {
            XCTAssert(false, "Unable to decode JSON fixture at \(path): \(error).")
            return [:]
        }
    }
}
