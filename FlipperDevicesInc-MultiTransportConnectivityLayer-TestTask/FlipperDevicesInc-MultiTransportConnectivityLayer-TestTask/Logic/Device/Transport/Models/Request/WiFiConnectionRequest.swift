import Foundation

struct WiFiConnectionRequest: Codable, Sendable {
    let ssid: String
    let password: String
}
