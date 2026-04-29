@testable import MapboxDirections
import XCTest

class CredentialsTests: XCTestCase {
    func testCredentialsCreation() {
        let testURL = URL(string: "https://example.com")!
        let subject = Credentials(accessToken: "test", host: testURL)

        XCTAssertEqual(subject.accessToken, "test")
        XCTAssertEqual(subject.host, testURL)
    }

    func testDefaultConfiguration() {
        let credentials = Credentials(accessToken: BogusToken)
        XCTAssertEqual(credentials.accessToken, BogusToken)
        XCTAssertEqual(credentials.host.absoluteString, "https://api.mapbox.com")
    }

    func testCustomConfiguration() {
        let token = "deadbeefcafebebe"
        let host = URL(string: "https://example.com")!
        let credentials = Credentials(accessToken: token, host: host)
        XCTAssertEqual(credentials.accessToken, token)
        XCTAssertEqual(credentials.host, host)
    }

    func testAccessTokenInjection() {
        let expected = "injected"
        UserDefaults.standard.set(expected, forKey: "MBXAccessToken")
        XCTAssertEqual(Directions.shared.credentials.accessToken, expected)
        addTeardownBlock {
            UserDefaults.standard.removeObject(forKey: "MBXAccessToken")
        }
    }

#if !os(Linux)
    @MainActor
    func testSkuToken() {
        let expectedToken = "a token"
        MBXAccounts.serviceSkuToken = expectedToken
        MBXAccounts.serviceAccessToken = Directions.shared.credentials.accessToken
        XCTAssertEqual(Directions.shared.credentials.skuToken, expectedToken)
        MBXAccounts.serviceSkuToken = nil
        MBXAccounts.serviceAccessToken = nil
    }

    func testSkuTokenWithMismatchedAccessToken() {
        MBXAccounts.serviceSkuToken = "a token"
        MBXAccounts.serviceAccessToken = UUID().uuidString
        XCTAssertEqual(Directions.shared.credentials.skuToken, nil)
        MBXAccounts.serviceSkuToken = nil
        MBXAccounts.serviceAccessToken = nil
    }
#endif
}

#if !os(Linux)
@objc(MBXAccounts)
final class MBXAccounts: NSObject {
    @objc static var serviceSkuToken: String?
    @objc static var serviceAccessToken: String?
}
#endif
