import Foundation
import Synchronization

final class DeviceTransportWithSendingErrorWhenNotConnected: AnyDeviceTransport {
    private let decoratee: AnyDeviceTransport
    private let lastConnectionState = Mutex<ConnectionState?>(nil)
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
        switch lastConnectionState.withLock(\.self) {
        case .connected: return try await decoratee.send(request)
        default: throw SendingRequestError()
        }
    }
    
    private func observeConnectionState() {
        observeConnectionStateTask.withLock { observeConnectionStateTask in
            observeConnectionStateTask = Task { [weak self] in
                guard let self else { return }
                
                for await connectionState in decoratee.connectionStateStream {
                    lastConnectionState.withLock { $0 = connectionState }
                }
            }
        }
    }
    
    deinit {
        observeConnectionStateTask.withLock { $0?.cancel() }
    }
}

extension AnyDeviceTransport {
    func withSendingErrorWhenNotConnected() -> AnyDeviceTransport {
        DeviceTransportWithSendingErrorWhenNotConnected(decoratee: self)
    }
}
