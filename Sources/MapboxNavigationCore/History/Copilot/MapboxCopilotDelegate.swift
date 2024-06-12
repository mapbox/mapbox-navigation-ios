import Foundation

public protocol MapboxCopilotDelegate: AnyObject, Sendable {
    func copilot(_ copilot: MapboxCopilot, didFinishRecording session: NavigationSession)
    func copilot(_ copilot: MapboxCopilot, didUploadHistoryFileForSession session: NavigationSession)
    func copilot(_ copilot: MapboxCopilot, didEncounterError error: CopilotError)
}

/// Default implementations do nothing
extension MapboxCopilotDelegate {
    func copilot(_ copilot: MapboxCopilot, didFinishRecording session: NavigationSession) {}
    func copilot(_ copilot: MapboxCopilot, didUploadHistoryFileForSession session: NavigationSession) {}
    func copilot(_ copilot: MapboxCopilot, didEncounterError error: CopilotError) {}
}
