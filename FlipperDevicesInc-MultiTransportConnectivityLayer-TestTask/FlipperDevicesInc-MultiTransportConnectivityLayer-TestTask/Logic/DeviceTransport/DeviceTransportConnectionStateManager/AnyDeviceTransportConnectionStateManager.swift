import Foundation

protocol AnyDeviceTransportConnectionStateManager: Sendable {
    typealias Action = @Sendable () async throws -> Void
    
    var connectionState: ConnectionState { get async }
    var connectionStateStream: AsyncStream<ConnectionState> { get }
    
    func connect(_ connect: Action) async
    func disconnect(_ disconnect: Action) async
    func failConnection(with error: Error) async
}
