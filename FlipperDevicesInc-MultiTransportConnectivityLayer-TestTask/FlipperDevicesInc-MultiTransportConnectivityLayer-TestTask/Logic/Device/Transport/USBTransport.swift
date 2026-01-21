import Foundation

private enum SupportedEndpoint: CaseIterable {
    case deviceInfo
    case wifiNetworks
    case wifiConnect
    case wifiDisconnect
    
    var rawValue: String {
        switch self {
        case .deviceInfo: DeviceRequestEndpoint.deviceInfo
        case .wifiNetworks: DeviceRequestEndpoint.wifiNetworks
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

final class USBTransport: AnyDeviceTransport {
    private let connectionStateManager: AnyDeviceTransportConnectionStateManager
    private let mockDeviceInfo: DeviceInfo
    private let mockWiFiNetworks: [WiFiNetwork]
    private let connectsSuccessfully: Bool
    
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
        mockWiFiNetworks: [WiFiNetwork],
        connectsSuccessfully: Bool = .random()
    ) {
        self.connectionStateManager = connectionStateManager
        self.mockDeviceInfo = mockDeviceInfo
        self.mockWiFiNetworks = mockWiFiNetworks
        self.connectsSuccessfully = connectsSuccessfully
    }
    
    func connect() async throws {
        try await connectionStateManager.connect { [connectsSuccessfully] in
            try await Task.longSleep()
            guard !connectsSuccessfully else { return }
            
            throw ConnectionError()
        }
    }
    
    func disconnect() async throws {
        try await connectionStateManager.disconnect {
            try await Task.mediumSleep()
        }
    }
    
    func send<T: Decodable>(_ request: DeviceRequest) async throws -> T {
        let endpoint = request.endpoint
        let data: Data
        
        switch SupportedEndpoint(endpoint: endpoint) {
        case .deviceInfo: data = try JSONEncoder().encode(mockDeviceInfo)
        case .wifiNetworks: data = try JSONEncoder().encode(mockWiFiNetworks)
        case .wifiConnect: data = Data()
        case .wifiDisconnect: data = Data()
        case .none: throw HandlingUnsupportedEndpointError(endpoint: endpoint)
        }
        
        return try await response(data)
    }
    
    private func response<T: Decodable>(_ data: Data) async throws -> T {
        try await Task.longSleep()
        return try JSONDecoder().decode(T.self, from: data)
    }
}
