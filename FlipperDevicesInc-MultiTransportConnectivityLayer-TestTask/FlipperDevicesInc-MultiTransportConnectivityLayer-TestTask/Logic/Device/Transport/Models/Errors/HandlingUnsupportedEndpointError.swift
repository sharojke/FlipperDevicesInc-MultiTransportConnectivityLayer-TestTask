import Foundation

struct HandlingUnsupportedEndpointError: AnyError {
    let endpoint: String
    
    var description: String {
        "\(Self.self) - \(endpoint)"
    }
}
