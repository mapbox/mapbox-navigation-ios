import XCTest
@testable import SwiftApiCompatibilityKit

final class SwiftApiCompatibilityCheckKitTests: XCTestCase {
    func testEmptyReportParsing() throws {
        let input = """

/* Generic Signature Changes */

/* RawRepresentable Changes */

/* Removed Decls */

/* Moved Decls */

/* Renamed Decls */

/* Type Changes */

/* Decl Attribute changes */

/* Fixed-layout Type Changes */

/* Protocol Conformance Change */

/* Protocol Requirement Change */

/* Class Inheritance Change */

/* Others */
"""

        let expectedReport: BreakingChangesReport = .init(entries: [
            .init(name: "Generic Signature Changes", changes: []),
            .init(name: "RawRepresentable Changes", changes: []),
            .init(name: "Removed Decls", changes: []),
            .init(name: "Moved Decls", changes: []),
            .init(name: "Renamed Decls", changes: []),
            .init(name: "Type Changes", changes: []),
            .init(name: "Decl Attribute changes", changes: []),
            .init(name: "Fixed-layout Type Changes", changes: []),
            .init(name: "Protocol Conformance Change", changes: []),
            .init(name: "Protocol Requirement Change", changes: []),
            .init(name: "Class Inheritance Change", changes: []),
            .init(name: "Others", changes: []),
        ])

        let actualReport = try BreakingChangesReport(swiftApiDigesterOutput: input)
        XCTAssertTrue(actualReport.isEmpty())

        XCTAssertEqual(actualReport, expectedReport)
    }

    func testFullReport() throws {
        let input = """


/* Generic Signature Changes */
1

/* RawRepresentable Changes */
2
3

/* Removed Decls */
4
5

/* Moved Decls */

/* Renamed Decls */
Var Accounts.serviceSkuToken has been renamed to Var serviceSkuToken2

/* Type Changes */
6

/* Decl Attribute changes */
7

/* Fixed-layout Type Changes */
8
9

/* Protocol Conformance Change */
10

/* Protocol Requirement Change */
11
12
13

/* Class Inheritance Change */

/* Others */
14

"""

        let expectedReport: BreakingChangesReport = .init(entries: [
            .init(name: "Generic Signature Changes", changes: [
                "1",
            ]),
            .init(name: "RawRepresentable Changes", changes: [
                "2",
                "3",
            ]),
            .init(name: "Removed Decls", changes: [
                "4",
                "5",
            ]),
            .init(name: "Moved Decls", changes: []),
            .init(name: "Renamed Decls", changes: [
                "Var Accounts.serviceSkuToken has been renamed to Var serviceSkuToken2",
            ]),
            .init(name: "Type Changes", changes: [
                "6",
            ]),
            .init(name: "Decl Attribute changes", changes: [
                "7",
            ]),
            .init(name: "Fixed-layout Type Changes", changes: [
                "8",
                "9",
            ]),
            .init(name: "Protocol Conformance Change", changes: [
                "10",
            ]),
            .init(name: "Protocol Requirement Change", changes: [
                "11",
                "12",
                "13",
            ]),
            .init(name: "Class Inheritance Change", changes: []),
            .init(name: "Others", changes: [
                "14",
            ]),
        ])

        let actualReport = try BreakingChangesReport(swiftApiDigesterOutput: input)
        XCTAssertFalse(actualReport.isEmpty())

        XCTAssertEqual(actualReport, expectedReport)
    }
}
