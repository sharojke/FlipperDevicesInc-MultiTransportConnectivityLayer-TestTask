import Foundation

enum ConnectionState: Sendable {
    case disconnected
    case discovering
    case connecting
    case connected
    case failed(Error)
}
