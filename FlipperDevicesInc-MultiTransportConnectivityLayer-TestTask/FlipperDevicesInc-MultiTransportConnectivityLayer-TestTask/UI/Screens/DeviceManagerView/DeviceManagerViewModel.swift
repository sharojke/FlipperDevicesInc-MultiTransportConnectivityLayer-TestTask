import Foundation

@MainActor
final class DeviceManagerViewModel: ObservableObject {
    private let deviceManager: AnyDeviceManager
    private var observeConnectionStateTask: Task<Void, Never>?
    
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
    
    deinit {
        observeConnectionStateTask?.cancel()
    }
}

private extension DeviceManagerViewModel {
    func log(_ message: String) {
        consoleText += "\(message)\n"
    }
    
    func observeConnectionState() {
        observeConnectionStateTask = Task { [weak self, deviceManager] in
            for await state in deviceManager.connectionStateStream {
                self?.log("--- Connection state changed: \(state)")
            }
        }
    }
}
