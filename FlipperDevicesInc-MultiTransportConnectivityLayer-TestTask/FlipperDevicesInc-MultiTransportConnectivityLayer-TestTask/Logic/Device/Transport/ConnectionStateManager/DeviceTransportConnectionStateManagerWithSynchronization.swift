import Foundation

actor DeviceTransportConnectionStateManagerWithSynchronization: AnyDeviceTransportConnectionStateManager {
    private let decoratee: AnyDeviceTransportConnectionStateManager
    private var currentTask: Task<Void, Error>?
    
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
    
    func connect(_ connect: @escaping Action) async throws {
        try await executeOperation { [decoratee] in
            try await decoratee.connect(connect)
        }
    }
    
    func disconnect(_ disconnect: @escaping Action) async throws {
        try await executeOperation { [decoratee] in
            try await decoratee.disconnect(disconnect)
        }
    }
    
    func failConnection(with error: Error) async {
        try? await executeOperation { [decoratee] in
            await decoratee.failConnection(with: error)
        }
    }
    
    private func executeOperation(_ operation: @escaping @Sendable () async throws -> Void) async throws {
        currentTask?.cancel()

        currentTask = Task {
            try Task.checkCancellation()
            try await operation()
        }
        
        try await currentTask?.value
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
