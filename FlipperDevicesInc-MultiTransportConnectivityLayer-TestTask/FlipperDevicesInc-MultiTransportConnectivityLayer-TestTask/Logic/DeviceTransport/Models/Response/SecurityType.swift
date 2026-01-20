import Foundation

enum SecurityType: String, Codable {
    case none = "OPEN"
    case wpa2 = "WPA2"
    case wpa3 = "WPA3"
    case wep = "WEP"
}
