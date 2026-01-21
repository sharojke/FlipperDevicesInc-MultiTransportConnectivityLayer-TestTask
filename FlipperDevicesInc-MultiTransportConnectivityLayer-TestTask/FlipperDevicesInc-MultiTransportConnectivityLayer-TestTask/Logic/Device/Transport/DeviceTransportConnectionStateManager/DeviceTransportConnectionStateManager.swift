import Foundation

actor DeviceTransportConnectionStateManager: AnyDeviceTransportConnectionStateManager {
    private let multicastConnectionStateStream: MulticastAsyncStream<ConnectionState>
    private(set) var connectionState: ConnectionState
    
    nonisolated var connectionStateStream: AsyncStream<ConnectionState> {
        multicastConnectionStateStream.stream()
    }
    
    init(multicastConnectionStateStream: MulticastAsyncStream<ConnectionState> = MulticastAsyncStream()) {
        self.multicastConnectionStateStream = multicastConnectionStateStream
        self.connectionState = .disconnected
    }

    func connect(_ connect: Action) async {
        guard connectionState.needsToConnect else { return }
        
        setConnectionState(.connecting)
        
        do {
            try await connect()
            setConnectionState(.connected)
        } catch {
            failConnection(with: error)
        }
    }
    
    func disconnect(_ disconnect: Action) async {
        guard connectionState.needsToDisconnect else { return }
        
        do {
            try await disconnect()
            setConnectionState(.disconnected)
        } catch {}
    }
    
    func failConnection(with error: Error) {
        setConnectionState(.failed(error))
    }
    
    private func setConnectionState(_ connectionState: ConnectionState) {
        self.connectionState = connectionState
        multicastConnectionStateStream.yield(connectionState)
    }
}

private extension ConnectionState {
    var needsToConnect: Bool {
        switch self {
        case .discovering, .connecting, .connected: false
        case .disconnected, .failed: true
        }
    }
    
    var needsToDisconnect: Bool {
        !needsToConnect
    }
}
