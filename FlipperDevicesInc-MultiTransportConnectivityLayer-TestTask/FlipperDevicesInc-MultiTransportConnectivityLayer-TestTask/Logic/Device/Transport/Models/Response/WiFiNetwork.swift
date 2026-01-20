import Foundation

struct WiFiNetwork: Codable {
    let ssid: String
    let signalStrength: Int
    let securityType: SecurityType
}
