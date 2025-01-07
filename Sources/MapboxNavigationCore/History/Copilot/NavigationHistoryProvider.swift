import Foundation

public enum NavigationHistoryProviderError: Error, Sendable {
    case noHistory
    case notFound(_ path: String)
}

public protocol NavigationHistoryProviderProtocol: AnyObject {
    typealias Filepath = String
    typealias DumpResult = Result<(Filepath, NavigationHistoryFormat), NavigationHistoryProviderError>

    @MainActor
    func startRecording()

    func pushEvent<T: NavigationHistoryEvent>(event: T) throws

    @MainActor
    func dumpHistory(_ completion: @escaping @Sendable (DumpResult) -> Void)
}
