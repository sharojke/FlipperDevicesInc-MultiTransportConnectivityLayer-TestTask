import Foundation

actor DeviceTransportWithSendingCancellationWhenNotConnected: AnyDeviceTransport {
    private let decoratee: AnyDeviceTransport
    private var sendTasks = [UUID: () -> Void]()
    private var observeConnectionStateTask: Task<Void, Never>?

    var isAvailable: Bool {
        get async {
            await decoratee.isAvailable
        }
    }
    
    nonisolated var connectionStateStream: AsyncStream<ConnectionState> {
        decoratee.connectionStateStream
    }
    
    init(decoratee: AnyDeviceTransport) {
        self.decoratee = decoratee
        
        Task { [weak self] in
            await self?.observeConnectionState()
        }
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
        
        sendTasks[id] = task.cancel        
        return try await task.value
    }
    
    private func observeConnectionState() {
        observeConnectionStateTask = Task { [weak self, decoratee] in
            for await connectionState in decoratee.connectionStateStream {
                switch connectionState {
                case .disconnected, .failed: await self?.cancelSendTasks()
                case .discovering, .connecting, .connected: break
                }
            }
        }
    }
    
    private func cancelSendTasks() {
        sendTasks.values.forEach { $0() }
        sendTasks.removeAll()
    }
    
    deinit {
        observeConnectionStateTask?.cancel()
    }
}

extension AnyDeviceTransport {
    func withSendingCancellationWhenNotConnected() -> AnyDeviceTransport {
        DeviceTransportWithSendingCancellationWhenNotConnected(decoratee: self)
    }
}
