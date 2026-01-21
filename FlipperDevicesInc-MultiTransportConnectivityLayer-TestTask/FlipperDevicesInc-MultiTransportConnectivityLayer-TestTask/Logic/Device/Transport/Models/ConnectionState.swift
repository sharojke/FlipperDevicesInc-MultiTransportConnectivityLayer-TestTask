import Foundation

enum ConnectionState: Sendable, Equatable {
    case disconnected
    case discovering
    case connecting
    case connected
    case failed(Error)
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.disconnected, .disconnected),
            (.discovering, .discovering),
            (.connecting, .connecting),
            (.connected, .connected),
            (.failed, .failed):
            true
            
        default:
            false
        }
    }
}
