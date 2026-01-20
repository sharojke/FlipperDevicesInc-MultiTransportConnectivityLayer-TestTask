import Foundation

protocol AnyDeviceTransport: Sendable {
    typealias ConnectionStateContinuation = AsyncStream<ConnectionState>.Continuation
    
    var isAvailable: Bool { get async }
    var connectionState: AsyncStream<ConnectionState> { get }
    
    func connect() async throws
    func disconnect() async throws
    func send<T: Decodable>(_ request: DeviceRequest) async throws -> T
}
