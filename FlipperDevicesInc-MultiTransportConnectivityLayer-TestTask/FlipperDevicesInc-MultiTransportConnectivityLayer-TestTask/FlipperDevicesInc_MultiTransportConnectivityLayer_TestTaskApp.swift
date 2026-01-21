import SwiftUI

@main
struct FlipperDevicesInc_MultiTransportConnectivityLayer_TestTaskApp: App {
    @StateObject private var router = Router()
    @State private var bleConnectsSuccessfully = true
    @State private var wifiConnectsSuccessfully = true
    @State private var usbConnectsSuccessfully = true
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path, root: mainView)
        }
    }
}

private extension FlipperDevicesInc_MultiTransportConnectivityLayer_TestTaskApp {
    func mainView() -> some View {
        let viewModel = MainViewModel(
            bleConnectsSuccessfully: $bleConnectsSuccessfully,
            wifiConnectsSuccessfully: $wifiConnectsSuccessfully,
            usbConnectsSuccessfully: $usbConnectsSuccessfully
        ) { router.push(.deviceManager) }
        return MainView(viewModel: viewModel)
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
            connectsSuccessfully: bleConnectsSuccessfully
        )
        return decoratedDeviceTransport(transport)
    }
    
    func wifiTransport() -> AnyDeviceTransport {
        let transport = WiFiTransport(
            connectionStateManager: decoratedDeviceTransportConnectionStateManager(),
            mockDeviceInfo: .wifi,
            connectsSuccessfully: wifiConnectsSuccessfully
        )
        return decoratedDeviceTransport(transport)
    }
    
    func usbTransport() -> AnyDeviceTransport {
        let transport = USBTransport(
            connectionStateManager: decoratedDeviceTransportConnectionStateManager(),
            mockDeviceInfo: .usb,
            mockWiFiNetworks: [.guest],
            connectsSuccessfully: usbConnectsSuccessfully
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
