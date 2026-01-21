import Foundation

actor DeviceTransportConnectionStateManagerWithSynchronization: AnyDeviceTransportConnectionStateManager {
    private let decoratee: AnyDeviceTransportConnectionStateManager
    private var currentTask: Task<Void, Never>?
    
    var connectionState: ConnectionState {
        get async {
            await decoratee.connectionState
        }
    }
    
    nonisolated var connectionStateStream: AsyncStream<ConnectionState> {
        decoratee.connectionStateStream
    }
    
    init(decoratee: AnyDeviceTransportConnectionStateManager) {
        self.decoratee = decoratee
    }
    
    func connect(_ connect: @escaping Action) {
        executeOperation { [decoratee] in
            await decoratee.connect(connect)
        }
    }
    
    func disconnect(_ disconnect: @escaping Action) {
        executeOperation { [decoratee] in
            await decoratee.disconnect(disconnect)
        }
    }
    
    func failConnection(with error: Error) {
        executeOperation { [decoratee] in
            await decoratee.failConnection(with: error)
        }
    }
    
    private func executeOperation(_ operation: @escaping @Sendable () async -> Void) {
        currentTask?.cancel()

        currentTask = Task {
            guard !Task.isCancelled else { return }
            
            await operation()
        }
    }
    
    deinit {
        currentTask?.cancel()
    }
}

extension AnyDeviceTransportConnectionStateManager {
    func withSynchronization() -> AnyDeviceTransportConnectionStateManager {
        DeviceTransportConnectionStateManagerWithSynchronization(decoratee: self)
    }
}
