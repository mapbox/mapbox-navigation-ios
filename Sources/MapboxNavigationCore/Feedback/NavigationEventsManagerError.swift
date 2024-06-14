import Foundation

/// An error that occures during event sending.
@_spi(MapboxInternal)
public enum NavigationEventsManagerError: LocalizedError {
    case failedToSend(reason: String)
    case invalidData
}
