import Foundation

private enum ActiveDeviceTransport {
    case primary(AnyDeviceTransport)
    case fallback(AnyDeviceTransport)
}

actor DeviceTransportOrchestrator: AnyDeviceTransport {
    private let primary: AnyDeviceTransport
    private let fallback: AnyDeviceTransport
    private let multicastConnectionStateStream: MulticastAsyncStream<ConnectionState>
    
    private var activeDeviceTransport: ActiveDeviceTransport
    private var lastConnectionState: ConnectionState?
    private var observePrimaryConnectionStateTask: Task<Void, Never>?
    private var observeFallbackConnectionStateTask: Task<Void, Never>?

    var isAvailable: Bool {
        get async {
            switch activeDeviceTransport {
            case .primary(let transport), .fallback(let transport):
                return await transport.isAvailable
            }
        }
    }
    
    nonisolated var connectionStateStream: AsyncStream<ConnectionState> {
        multicastConnectionStateStream.stream()
    }
    
    init(
        primary: AnyDeviceTransport,
        fallback: AnyDeviceTransport,
        multicastConnectionStateStream: MulticastAsyncStream<ConnectionState> = MulticastAsyncStream()
    ) {
        self.primary = primary
        self.fallback = fallback
        self.multicastConnectionStateStream = multicastConnectionStateStream
        self.activeDeviceTransport = .primary(primary)
        
        Task { [weak self] in
            await self?.observeConnectionState()
        }
    }
    
    func connect() async throws {
        switch activeDeviceTransport {
        case .primary(let transport):
            try await handleLastConnectionStateIfNotConnected {
                do {
                    try await transport.connect()
                } catch {
                    if error is CancellationError { return }
                    
                    self.activeDeviceTransport = .fallback(fallback)
                    try await fallback.connect()
                }
            }
            
        case .fallback:
            try await handleLastConnectionStateIfNotConnected {
                self.activeDeviceTransport = .primary(primary)
                try await connect()
            }
        }
    }
    
    func disconnect() async throws {
        switch activeDeviceTransport {
        case .primary(let transport), .fallback(let transport):
            try await transport.disconnect()
        }
    }
    
    func send<T: Decodable & Sendable>(_ request: DeviceRequest) async throws -> T {
        switch activeDeviceTransport {
        case .primary(let transport), .fallback(let transport):
            try await transport.send(request)
        }
    }
    
    private func observeConnectionState() {
        observePrimaryConnectionStateTask = Task { [weak self, primary] in
            for await connectionState in primary.connectionStateStream {
                switch await self?.activeDeviceTransport {
                case .primary: await self?.handleReceivedConnectionState(connectionState)
                case .fallback, .none: break
                }
            }
        }
        
        observeFallbackConnectionStateTask = Task { [weak self, fallback] in
            for await connectionState in fallback.connectionStateStream {
                switch await self?.activeDeviceTransport {
                case .primary: break
                case .fallback, .none: await self?.handleReceivedConnectionState(connectionState)
                }
            }
        }
    }
    
    private func handleLastConnectionStateIfNotConnected(_ handle: () async throws -> Void) async throws {
        switch lastConnectionState {
        case .connected: break
        default: try await handle()
        }
    }
    
    private func handleReceivedConnectionState(_ connectionState: ConnectionState) {
        lastConnectionState = connectionState
        multicastConnectionStateStream.yield(connectionState)
    }
    
    deinit {
        observePrimaryConnectionStateTask?.cancel()
        observeFallbackConnectionStateTask?.cancel()
    }
}

extension AnyDeviceTransport {
    func withFallback(_ fallback: AnyDeviceTransport) -> AnyDeviceTransport {
        DeviceTransportOrchestrator(primary: self, fallback: fallback)
    }
}
