import Foundation


@objc(MBLocationRecordingProtocol)
public protocol LocationRecordingProtocol {
    func enableLocationRecording()
    func disableLocationRecording()
    func locationHistory() -> String
}
