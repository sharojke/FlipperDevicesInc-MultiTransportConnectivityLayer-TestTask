import Foundation
import Synchronization

private enum ActiveDeviceTransport {
    case primary(AnyDeviceTransport)
    case fallback(AnyDeviceTransport)
}

final class DeviceTransportOrchestrator: AnyDeviceTransport {
    private let primary: AnyDeviceTransport
    private let fallback: AnyDeviceTransport
    private let activeDeviceTransport: Mutex<ActiveDeviceTransport>
    private let multicastConnectionStateStream: MulticastAsyncStream<ConnectionState>
    private let lastConnectionState = Mutex<ConnectionState?>(nil)
    private let observeConnectionStateTask = Mutex<Task<Void, Never>?>(nil)

    var isAvailable: Bool {
        get async {
            switch activeDeviceTransport.withLock(\.self) {
            case .primary(let transport), .fallback(let transport):
                return await transport.isAvailable
            }
        }
    }
    
    var connectionStateStream: AsyncStream<ConnectionState> {
        multicastConnectionStateStream.stream()
    }
    
    init(
        primary: AnyDeviceTransport,
        fallback: AnyDeviceTransport,
        multicastConnectionStateStream: MulticastAsyncStream<ConnectionState> = MulticastAsyncStream()
    ) {
        self.primary = primary
        self.fallback = fallback
        self.activeDeviceTransport = Mutex(.primary(primary))
        self.multicastConnectionStateStream = multicastConnectionStateStream
        observeConnectionState()
    }
    
    func connect() async throws {
        switch activeDeviceTransport.withLock(\.self) {
        case .primary(let transport):
            switch lastConnectionState.withLock(\.self) {
            case .connected:
                break
                
            default:
                do {
                    try await transport.connect()
                } catch {
                    self.activeDeviceTransport.withLock { $0 = .fallback(fallback) }
                    try await fallback.connect()
                }
            }
            
        case .fallback:
            switch lastConnectionState.withLock(\.self) {
            case .connected:
                break
                
            default:
                self.activeDeviceTransport.withLock { $0 = .primary(primary) }
                try await primary.connect()
            }
        }
    }
    
    func disconnect() async throws {
        switch activeDeviceTransport.withLock(\.self) {
        case .primary(let transport), .fallback(let transport): try await transport.disconnect()
        }
    }
    
    func send<T: Decodable & Sendable>(_ request: DeviceRequest) async throws -> T {
        switch activeDeviceTransport.withLock(\.self) {
        case .primary(let transport), .fallback(let transport):
            try await transport.send(request)
        }
    }
    
    private func observeConnectionState() {
        observeConnectionStateTask.withLock { observeConnectionStateTask in
            observeConnectionStateTask = Task { [weak self] in
                guard let self else { return }
                
                async let primaryTask: Void = {
                    for await primaryConnectionState in primary.connectionStateStream {
                        switch activeDeviceTransport.withLock(\.self) {
                        case .primary: handleReceivedConnectionState(primaryConnectionState)
                        case .fallback: break
                        }
                    }
                }()
                
                async let fallbackTask: Void = {
                    for await fallbackConnectionState in fallback.connectionStateStream {
                        switch activeDeviceTransport.withLock(\.self) {
                        case .primary: break
                        case .fallback: handleReceivedConnectionState(fallbackConnectionState)
                        }
                    }
                }()
                
                _ = await (primaryTask, fallbackTask)
            }
        }
    }
    
    private func handleReceivedConnectionState(_ connectionState: ConnectionState) {
        lastConnectionState.withLock { $0 = connectionState }
        multicastConnectionStateStream.yield(connectionState)
    }
    
    deinit {
        observeConnectionStateTask.withLock { $0?.cancel() }
    }
}

extension AnyDeviceTransport {
    func withFallback(_ fallback: AnyDeviceTransport) -> AnyDeviceTransport {
        DeviceTransportOrchestrator(primary: self, fallback: fallback)
    }
}
