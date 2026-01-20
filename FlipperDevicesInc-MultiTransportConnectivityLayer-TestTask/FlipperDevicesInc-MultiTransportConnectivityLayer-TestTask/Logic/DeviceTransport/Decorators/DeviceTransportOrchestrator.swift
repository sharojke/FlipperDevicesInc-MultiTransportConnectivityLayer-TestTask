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
    private let lastConnectionState = Mutex<ConnectionState?>(nil)

    var isAvailable: Bool {
        get async {
            switch activeDeviceTransport.withLock(\.self) {
            case .primary(let transport), .fallback(let transport):
                return await transport.isAvailable
            }
        }
    }
    
    var connectionStateStream: AsyncStream<ConnectionState> {
        activeDeviceTransport.withLock { transport in
            switch transport {
            case .primary(let transport), .fallback(let transport): transport.connectionStateStream
            }
        }
    }
    
    init(primary: AnyDeviceTransport, fallback: AnyDeviceTransport) {
        self.primary = primary
        self.fallback = fallback
        self.activeDeviceTransport = Mutex(.primary(primary))
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
        Task { [weak self] in
            guard let self else { return }
            
            let activeDeviceTransport = switch activeDeviceTransport.withLock(\.self) {
            case .primary(let transport), .fallback(let transport): transport
            }
            
            for await connectionState in activeDeviceTransport.connectionStateStream {
                lastConnectionState.withLock { $0 = connectionState }
            }
        }
    }
}

extension AnyDeviceTransport {
    func withFallback(_ fallback: AnyDeviceTransport) -> AnyDeviceTransport {
        DeviceTransportOrchestrator(primary: self, fallback: fallback)
    }
}
