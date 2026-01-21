import Foundation
import Synchronization

final class DeviceTransportWithSendingCancellationWhenNotConnected: AnyDeviceTransport {
    private let decoratee: AnyDeviceTransport
    private let sendTasks = Mutex<[UUID: () -> Void]>([:])
    private let observeConnectionStateTask = Mutex<Task<Void, Never>?>(nil)

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
        
        let task = Task<T, Error> { [decoratee] in
            try await decoratee.send(request)
        }
        
        sendTasks.withLock { $0[id] = task.cancel }
        defer { sendTasks.withLock { _ = $0.removeValue(forKey: id) } }
        
        return try await task.value
    }
    
    private func observeConnectionState() {
        observeConnectionStateTask.withLock { observeConnectionStateTask in
            observeConnectionStateTask = Task { [weak self] in
                await self?.runObserveConnectionStateTask()
            }
        }
    }
    
    private func runObserveConnectionStateTask() async {
        for await connectionState in decoratee.connectionStateStream {
            print(connectionState)
            
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
    
    deinit {
        observeConnectionStateTask.withLock { $0?.cancel() }
    }
}

extension AnyDeviceTransport {
    func withSendingCancellationWhenNotConnected() -> AnyDeviceTransport {
        DeviceTransportWithSendingCancellationWhenNotConnected(decoratee: self)
    }
}
