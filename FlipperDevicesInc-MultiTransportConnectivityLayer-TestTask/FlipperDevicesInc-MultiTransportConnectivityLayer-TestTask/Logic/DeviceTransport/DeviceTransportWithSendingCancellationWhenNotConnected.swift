import Foundation
import Synchronization

final class DeviceTransportWithSendingCancellationWhenNotConnected: AnyDeviceTransport {
    private let decoratee: AnyDeviceTransport
    private let sendTasks = Mutex<[UUID: () -> Void]>([:])

    var isAvailable: Bool {
        get async {
            await decoratee.isAvailable
        }
    }
    
    var connectionStateStream: AsyncStream<ConnectionState> {
        decoratee.connectionStateStream
    }
    
    init(decoratee: AnyDeviceTransport) {
        self.decoratee = decoratee
        observeConnectionState()
    }
    
    func connect() async throws {
        try await decoratee.connect()
    }
    
    func disconnect() async throws {
        try await decoratee.disconnect()
    }
    
    func send<T: Decodable & Sendable>(_ request: DeviceRequest) async throws -> T {
        let id = UUID()
        defer { sendTasks.withLock { _ = $0.removeValue(forKey: id) } }
        
        let task = Task<T, Error> { [decoratee] in
            try await decoratee.send(request)
        }
        
        sendTasks.withLock { $0[id] = task.cancel }
        let result = try await task.value
        try Task.checkCancellation()
        return result
    }
    
    private func observeConnectionState() {
        Task { [weak self] in
            guard let self else { return }
            
            for await connectionState in decoratee.connectionStateStream {
                switch connectionState {
                case .disconnected, .failed:
                    sendTasks.withLock { task in
                        task.values.forEach { $0() }
                        task.removeAll()
                    }
                    
                case .discovering, .connecting, .connected:
                    break
                }
            }
        }
    }
}

extension AnyDeviceTransport {
    func withSendingCancellationWhenNotConnected() -> AnyDeviceTransport {
        DeviceTransportWithSendingCancellationWhenNotConnected(decoratee: self)
    }
}
