import SwiftUI

@MainActor
final class MainViewModel: ObservableObject {
    private let onDidPressShowDeviceManager: () -> Void
    
    @Binding var bleConnectsSuccessfully: Bool
    @Binding var wifiConnectsSuccessfully: Bool
    @Binding var usbConnectsSuccessfully: Bool
    
    init(
        bleConnectsSuccessfully: Binding<Bool>,
        wifiConnectsSuccessfully: Binding<Bool>,
        usbConnectsSuccessfully: Binding<Bool>,
        onDidPressShowDeviceManager: @escaping () -> Void
    ) {
        self._bleConnectsSuccessfully = bleConnectsSuccessfully
        self._wifiConnectsSuccessfully = wifiConnectsSuccessfully
        self._usbConnectsSuccessfully = usbConnectsSuccessfully
        self.onDidPressShowDeviceManager = onDidPressShowDeviceManager
    }
    
    func handleDidPressShowDeviceManager() {
        onDidPressShowDeviceManager()
    }
}
