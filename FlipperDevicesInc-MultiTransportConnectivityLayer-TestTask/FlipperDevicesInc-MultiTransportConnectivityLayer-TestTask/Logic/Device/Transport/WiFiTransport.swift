import Foundation

private enum SupportedEndpoint: CaseIterable {
    case deviceInfo
    case wifiConnect
    case wifiDisconnect
    
    var rawValue: String {
        switch self {
        case .deviceInfo: DeviceRequestEndpoint.deviceInfo
        case .wifiConnect: DeviceRequestEndpoint.wifiConnect
        case .wifiDisconnect: DeviceRequestEndpoint.wifiDisconnect
        }
    }
    
    init?(endpoint: String) {
        let endpoint = Self.allCases.first { endpoint == $0.rawValue }
        guard let endpoint else { return nil }
        
        self = endpoint
    }
}

final class WiFiTransport: AnyDeviceTransport {
    private let connectionStateManager: AnyDeviceTransportConnectionStateManager
    private let mockDeviceInfo: DeviceInfo
    private let connectsSuccessfully: Bool
    private let sendsRequestSuccessfully: Bool
    
    var isAvailable: Bool {
        get async {
            try? await Task.shortSleep()
            return true
        }
    }
    
    var connectionStateStream: AsyncStream<ConnectionState> {
        connectionStateManager.connectionStateStream
    }
    
    init(
        connectionStateManager: AnyDeviceTransportConnectionStateManager,
        mockDeviceInfo: DeviceInfo,
        connectsSuccessfully: Bool = .random(),
        sendsRequestSuccessfully: Bool = .random()
    ) {
        self.connectionStateManager = connectionStateManager
        self.mockDeviceInfo = mockDeviceInfo
        self.connectsSuccessfully = connectsSuccessfully
        self.sendsRequestSuccessfully = sendsRequestSuccessfully
    }
    
    func connect() async throws {
        await connectionStateManager.connect { [connectsSuccessfully] in
            try await Task.longSleep()
            guard !connectsSuccessfully else { return }
            
            throw ConnectionError()
        }
    }
    
    func disconnect() async throws {
        await connectionStateManager.disconnect {
            try await Task.mediumSleep()
        }
    }
    
    func send<T: Decodable>(_ request: DeviceRequest) async throws -> T {
        let endpoint = request.endpoint
        let data: Data
        
        switch SupportedEndpoint(endpoint: endpoint) {
        case .deviceInfo: data = try JSONEncoder().encode(mockDeviceInfo)
        case .wifiConnect: data = Data()
        case .wifiDisconnect: data = Data()
        case .none: throw HandlingUnsupportedEndpointError(endpoint: endpoint)
        }
        
        return try await response(data)
    }
    
    private func response<T: Decodable>(_ data: Data) async throws -> T {
        if sendsRequestSuccessfully {
            try await Task.veryLongSleep()
            return try JSONDecoder().decode(T.self, from: data)
        } else {
            throw SendingRequestError()
        }
    }
}
