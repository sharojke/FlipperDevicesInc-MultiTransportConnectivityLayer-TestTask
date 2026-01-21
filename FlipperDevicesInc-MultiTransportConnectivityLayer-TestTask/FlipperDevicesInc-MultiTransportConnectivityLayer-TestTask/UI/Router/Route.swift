import SwiftUI

enum Route: Identifiable, Hashable {
    case deviceManager
    
    var id: String {
        switch self {
        case .deviceManager: "deviceManager"
        }
    }
}
