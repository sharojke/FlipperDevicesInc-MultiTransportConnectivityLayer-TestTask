import SwiftUI

struct DeviceManagerView: View {
    @ObservedObject var viewModel: DeviceManagerViewModel
    
    var body: some View {
        let spacing: CGFloat = 20
        VStack(spacing: spacing) {
            HStack(spacing: spacing) {
                VStack(spacing: spacing) {
                    Button("connect") { viewModel.handleDidPressConnect() }
                    Button("disconnect") { viewModel.handleDidPressDisconnect() }
                }
                VStack(spacing: spacing) {
                    Button("deviceInfo") { viewModel.handleDidPressDeviceInfo() }
                    Button("wifiNetworks") { viewModel.handleDidPressWiFiNetworks() }
                }
            }
            
            ScrollView {
                TextEditor(text: $viewModel.consoleText)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
    }
}
