import Foundation

struct WiFiNetwork: Codable, Equatable {
    let ssid: String
    let signalStrength: Int
    let securityType: SecurityType
}

// swiftlint:disable no_magic_numbers
extension WiFiNetwork {
    static var home: Self {
        Self(ssid: "HomeWiFi", signalStrength: 80, securityType: .wpa2)
    }
    
    static var guest: Self {
        Self(ssid: "Guest", signalStrength: 60, securityType: .wpa2)
    }
}
// swiftlint:enable no_magic_numbers
