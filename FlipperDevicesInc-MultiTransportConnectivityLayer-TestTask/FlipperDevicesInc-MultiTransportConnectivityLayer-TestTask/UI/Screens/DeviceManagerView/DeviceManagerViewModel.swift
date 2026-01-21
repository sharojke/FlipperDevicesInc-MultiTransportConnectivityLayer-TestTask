import Foundation

@MainActor
final class DeviceManagerViewModel: ObservableObject {
    private let deviceManager: AnyDeviceManager
    
    @Published var consoleText: String = ""
    
    init(deviceManager: AnyDeviceManager) {
        self.deviceManager = deviceManager
        observeConnectionState()
    }
    
    func handleDidPressConnect() {
        Task { [weak self] in
            do {
                try await self?.deviceManager.connect()
            } catch {
                self?.log("-- Connect failed: \(error.nsDescription)")
            }
        }
    }
    
    func handleDidPressDisconnect() {
        Task { [weak self] in
            do {
                try await self?.deviceManager.disconnect()
            } catch {
                self?.log("-- Disconnect failed: \(error.nsDescription)")
            }
        }
    }
    
    func handleDidPressDeviceInfo() {
        Task { [weak self] in
            do {
                let info = try await self?.deviceManager.deviceInfo()
                self?.log("- Device Info: \(info as Any)")
            } catch {
                self?.log("-- Failed to get device info: \(error.nsDescription)")
            }
        }
    }
        
        func handleDidPressWiFiNetworks() {
            Task { [weak self] in
                do {
                    let networks = try await self?.deviceManager.wifiNetworks()
                    let list = networks.map { "(\($0)\n" }
                    self?.log("- Wi-Fi Networks:\n\(list as Any)")
                } catch {
                    self?.log("-- Failed to scan Wi-Fi networks: \(error.nsDescription)")
                }
            }
        }
    
    func handleDidPressConnectToWiFi() {
        Task { [weak self] in
            let ssid = "MyWiSSID"
            let password = "123"
            
            do {
                try await self?.deviceManager.connectToWiFi(ssid: ssid, password: password)
                self?.log("- Device connected to Wi-Fi \(ssid).")
            } catch {
                self?.log("-- Failed to connect device to Wi-Fi: \(error.nsDescription)")
            }
        }
    }
}

private extension DeviceManagerViewModel {
    func log(_ message: String) {
        consoleText += "\(message)\n"
    }
    
    func observeConnectionState() {
        Task { [weak self, deviceManager] in
            for await state in deviceManager.connectionStateStream {
                self?.log("--- Connection state changed: \(state)")
            }
        }
    }
}
