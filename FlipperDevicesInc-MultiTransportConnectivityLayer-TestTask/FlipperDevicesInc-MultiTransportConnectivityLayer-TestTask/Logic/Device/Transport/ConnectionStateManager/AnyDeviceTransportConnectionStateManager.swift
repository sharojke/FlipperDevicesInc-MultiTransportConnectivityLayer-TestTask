import Foundation

protocol AnyDeviceTransportConnectionStateManager: Sendable {
    typealias Action = @Sendable () async throws -> Void
    
    var connectionState: ConnectionState { get async }
    var connectionStateStream: AsyncStream<ConnectionState> { get }
    
    func connect(_ connect: @escaping Action) async
    func disconnect(_ disconnect: @escaping Action) async
    func failConnection(with error: Error) async
}
