import SwiftUI

@main
struct FlipperDevicesInc_MultiTransportConnectivityLayer_TestTaskApp: App {
    private lazy var deviceManager = DeviceManager(deviceTransport: deviceTransportOrchestrator())
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

private extension FlipperDevicesInc_MultiTransportConnectivityLayer_TestTaskApp {
    func deviceTransportOrchestrator() -> AnyDeviceTransport {
        bleTransport()
            .withFallback(wifiTransport())
            .withFallback(usbTransport())
    }
    
    private func bleTransport() -> AnyDeviceTransport {
        let transport = BLETransport(
            connectionStateManager: DeviceTransportConnectionStateManager(),
            mockDeviceInfo: .ble,
            mockWiFiNetworks: [.home]
        )
        return decoratedDeviceTransport(transport)
    }
    
    private func wifiTransport() -> AnyDeviceTransport {
        let transport = WiFiTransport(
            connectionStateManager: DeviceTransportConnectionStateManager(),
            mockDeviceInfo: .wifi
        )
        return decoratedDeviceTransport(transport)
    }
    
    private func usbTransport() -> AnyDeviceTransport {
        let transport = USBTransport(
            connectionStateManager: DeviceTransportConnectionStateManager(),
            mockDeviceInfo: .usb,
            mockWiFiNetworks: [.guest]
        )
        return decoratedDeviceTransport(transport)
    }
    
    private func decoratedDeviceTransport(_ deviceTransport: AnyDeviceTransport) -> AnyDeviceTransport {
        deviceTransport
            .withSendingCancellationWhenNotConnected()
            .withSendingErrorWhenNotConnected()
    }
}
