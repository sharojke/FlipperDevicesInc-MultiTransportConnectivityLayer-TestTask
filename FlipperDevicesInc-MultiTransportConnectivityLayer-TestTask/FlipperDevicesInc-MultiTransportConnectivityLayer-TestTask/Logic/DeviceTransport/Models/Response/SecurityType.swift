import Foundation

enum SecurityType: String, Codable {
    case open = "OPEN"
    case wpa2 = "WPA2"
    case wpa3 = "WPA3"
    case wep = "WEP"
}
