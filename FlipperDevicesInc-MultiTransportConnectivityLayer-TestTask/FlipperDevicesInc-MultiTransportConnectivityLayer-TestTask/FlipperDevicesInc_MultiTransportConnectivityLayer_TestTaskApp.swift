import SwiftUI

@main
struct FlipperDevicesInc_MultiTransportConnectivityLayer_TestTaskApp: App {
    @StateObject private var router = Router()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path, root: mainView)
        }
    }
}

private extension FlipperDevicesInc_MultiTransportConnectivityLayer_TestTaskApp {
    func mainView() -> some View {
        MainView { router.push(.deviceManager) }
            .navigationDestination(for: Route.self) { route in
                switch route {
                case .deviceManager: deviceManagerView()
                }
            }
    }
    
    func deviceManagerView() -> some View {
        let viewModel = DeviceManagerViewModel(deviceManager: deviceManager())
        return DeviceManagerView(viewModel: viewModel)
    }
}

private extension FlipperDevicesInc_MultiTransportConnectivityLayer_TestTaskApp {
    func deviceManager() -> AnyDeviceManager {
        DeviceManager(deviceTransport: deviceTransportOrchestrator())
    }
    
    func deviceTransportOrchestrator() -> AnyDeviceTransport {
        bleTransport()
            .withFallback(wifiTransport())
            .withFallback(usbTransport())
    }
    
    func bleTransport() -> AnyDeviceTransport {
        let transport = BLETransport(
            connectionStateManager: decoratedDeviceTransportConnectionStateManager(),
            mockDeviceInfo: .ble,
            mockWiFiNetworks: [.home],
//            connectsSuccessfully: false
        )
        return decoratedDeviceTransport(transport)
    }
    
    func wifiTransport() -> AnyDeviceTransport {
        let transport = WiFiTransport(
            connectionStateManager: decoratedDeviceTransportConnectionStateManager(),
            mockDeviceInfo: .wifi,
//            connectsSuccessfully: false
        )
        return decoratedDeviceTransport(transport)
    }
    
    func usbTransport() -> AnyDeviceTransport {
        let transport = USBTransport(
            connectionStateManager: decoratedDeviceTransportConnectionStateManager(),
            mockDeviceInfo: .usb,
            mockWiFiNetworks: [.guest],
//            connectsSuccessfully: true
        )
        return decoratedDeviceTransport(transport)
    }
    
    func decoratedDeviceTransport(_ deviceTransport: AnyDeviceTransport) -> AnyDeviceTransport {
        deviceTransport
            .withSendingCancellationWhenNotConnected()
            .withSendingErrorWhenNotConnected()
    }
    
    func decoratedDeviceTransportConnectionStateManager() -> AnyDeviceTransportConnectionStateManager {
        DeviceTransportConnectionStateManager().withSynchronization()
    }
}
