import Foundation
import SnapshotTesting
import XCTest

let snapshotDeviceName: String = {
    return ProcessInfo.processInfo
        .environment["SIMULATOR_MODEL_IDENTIFIER"]!
        .replacingOccurrences(of: ",", with: "_")
}()

let operatingSystemVersion: String = UIDevice.current.systemVersion

func assertImageSnapshot<Value, Format>(
    matching value: @autoclosure () throws -> Value,
    as snapshotting: Snapshotting<Value, Format>,
    named name: String? = nil,
    record recording: Bool = false,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
) {
    let fileUrl = URL(fileURLWithPath: "\(file)", isDirectory: false)
    let fileName = fileUrl.deletingPathExtension().lastPathComponent

    let snapshotDirectoryUrl = fileUrl
        .deletingLastPathComponent()
        .appendingPathComponent("__Snapshots__")
        .appendingPathComponent(snapshotDeviceName)
        .appendingPathComponent(operatingSystemVersion)
        .appendingPathComponent(fileName)

    let failure = verifySnapshot(
        matching: try value(),
        as: snapshotting,
        named: name,
        record: recording,
        snapshotDirectory: snapshotDirectoryUrl.path,
        timeout: timeout,
        file: file,
        testName: testName,
        line: line
    )
    guard let message = failure else { return }
    XCTFail(message, file: file, line: line)
}
