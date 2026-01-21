import SwiftUI

struct MainView: View {
    let onDidPressDeviceManager: () -> Void
    
    var body: some View {
        VStack {
            Text(description())
                .padding()
            Button("Show DeviceManagerView") {
                onDidPressDeviceManager()
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
        A successful connection is randomly set. 
        
        So if you have the same behavior, just pop and push DeviceManagerView again
        """
    }
}
