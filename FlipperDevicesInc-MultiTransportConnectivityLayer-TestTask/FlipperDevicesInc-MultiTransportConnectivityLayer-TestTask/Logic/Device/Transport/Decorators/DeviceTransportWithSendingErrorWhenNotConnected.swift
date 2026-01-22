import Foundation

actor DeviceTransportWithSendingErrorWhenNotConnected: AnyDeviceTransport {
    private let decoratee: AnyDeviceTransport
    private var lastConnectionState: ConnectionState?
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
        switch lastConnectionState {
        case .connected: return try await decoratee.send(request)
        default: throw SendingRequestError()
        }
    }
    
    private func observeConnectionState() {
        observeConnectionStateTask = Task { [weak self, decoratee] in
            for await connectionState in decoratee.connectionStateStream {
                await self?.setLastConnectionState(connectionState)
            }
        }
    }
    
    private func setLastConnectionState(_ connectionState: ConnectionState) {
        lastConnectionState = connectionState
    }
    
    deinit {
        observeConnectionStateTask?.cancel()
    }
}

extension AnyDeviceTransport {
    func withSendingErrorWhenNotConnected() -> AnyDeviceTransport {
        DeviceTransportWithSendingErrorWhenNotConnected(decoratee: self)
    }
}
