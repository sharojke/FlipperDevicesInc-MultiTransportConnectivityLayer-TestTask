import Foundation

final class DeviceManager: AnyDeviceManager {
    private let deviceTransport: AnyDeviceTransport
    
    var connectionStateStream: AsyncStream<ConnectionState> {
        deviceTransport.connectionStateStream
    }
    
    init(deviceTransport: AnyDeviceTransport) {
        self.deviceTransport = deviceTransport
    }
    
    func connect() async throws {
        try await deviceTransport.connect()
    }
    
    func disconnect() async throws {
        try await deviceTransport.disconnect()
    }
    
    func deviceInfo() async throws -> DeviceInfo {
        let request = DeviceRequest(endpoint: DeviceRequestEndpoint.deviceInfo, method: .get)
        return try await deviceTransport.send(request)
    }
    
    func wifiNetworks() async throws -> [WiFiNetwork] {
        let request = DeviceRequest(endpoint: DeviceRequestEndpoint.wifiNetworks, method: .get)
        return try await deviceTransport.send(request)
    }
    
    func connectToWiFi(ssid: String, password: String) async throws {
        let connectionRequest = WiFiConnectionRequest(ssid: ssid, password: password)
        let body = try JSONEncoder().encode(connectionRequest)
        let request = DeviceRequest(
            endpoint: DeviceRequestEndpoint.wifiConnect,
            method: .post,
            body: body
        )
        let _: String = try await deviceTransport.send(request)
    }
}
