import Foundation

struct DeviceInfo: Codable {
    let name: String
    let firmwareVersion: String
    let batteryLevel: Int
}
