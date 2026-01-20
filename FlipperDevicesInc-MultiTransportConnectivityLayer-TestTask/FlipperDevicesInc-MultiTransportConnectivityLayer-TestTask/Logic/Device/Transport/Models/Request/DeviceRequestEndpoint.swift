import Foundation

enum DeviceRequestEndpoint {
    static var deviceInfo: String { "/api/device/info" }
    static var wifiNetworks: String { "/api/wifi/networks" }
    static var wifiConnect: String { "/api/wifi/connect" }
    static var wifiDisconnect: String { "/api/wifi/disconnect" }
    static var firmwareUpload: String { "/api/firmware/upload" }
}
