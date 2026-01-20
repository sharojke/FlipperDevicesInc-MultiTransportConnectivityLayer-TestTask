import Foundation

struct DeviceInfo: Codable {
    let name: String
    let firmwareVersion: String
    let batteryLevel: Int
}

// swiftlint:disable no_magic_numbers
extension DeviceInfo {
    static var ble: Self {
        Self(name: "IoT Device BLE", firmwareVersion: "1.2.3", batteryLevel: 85)
    }
    
    static var wifi: Self {
        Self(name: "IoT Device WiFi", firmwareVersion: "1.3.0", batteryLevel: 92)
    }
    
    static var usb: Self {
        Self(name: "IoT Device USB", firmwareVersion: "1.4.0", batteryLevel: 95)
    }
}
// swiftlint:enable no_magic_numbers
