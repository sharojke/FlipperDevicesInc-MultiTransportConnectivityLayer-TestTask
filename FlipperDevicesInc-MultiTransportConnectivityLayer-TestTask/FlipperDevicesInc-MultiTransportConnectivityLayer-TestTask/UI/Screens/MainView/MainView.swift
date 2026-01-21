import SwiftUI

struct MainView: View {
    @ObservedObject var viewModel: MainViewModel

    var body: some View {
        VStack {
            Toggle("BLE Connects Successfully", isOn: $viewModel.bleConnectsSuccessfully)
                .padding()
            
            Toggle("WiFi Connects Successfully", isOn: $viewModel.wifiConnectsSuccessfully)
                .padding()
            
            Toggle("USB Connects Successfully", isOn: $viewModel.usbConnectsSuccessfully)
                .padding()
                
            Text(description())
                .padding()
            
            Button("Show DeviceManagerView") {
                viewModel.handleDidPressShowDeviceManager()
            }
            .foregroundStyle(.white)
            .padding()
            .background(.blue)
            .clipShape(Capsule())
        }
    }
    
    private func description() -> String {
        """
        DeviceManagerViewModel holds a DeviceManager, 
        that can perform Device Operations 
        such as connect/disconnect/get device info/etc.

        DeviceManager is configured using AnyDeviceTransport which is DeviceTransportOrchestrator under the hood.
        The Orchestrator reconnects to another transport (BLE → WiFi → USB) when the connection fails.
        
        You can configure a successful connection using the toggles above.
        """
    }
}
