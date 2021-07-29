import Foundation
import MultipeerKit

public struct PeerPayload<T>: Identifiable {
    public init(payload: T, sender: Peer) {
        self.payload = payload
        self.sender = sender
    }

    public let id: UUID = .init()
    public let payload: T
    public let sender: Peer
}

