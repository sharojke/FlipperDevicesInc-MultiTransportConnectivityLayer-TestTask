import Foundation

protocol AnyDeviceManager: Sendable {
    var connectionStateStream: AsyncStream<ConnectionState> { get }
    
    func connect() async throws
    func disconnect() async throws
    func deviceInfo() async throws -> DeviceInfo
    func wifiNetworks() async throws -> [WiFiNetwork]
    func connectToWiFi(ssid: String, password: String) async throws
}
