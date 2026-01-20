import Foundation

struct DeviceRequest: Sendable {
    let endpoint: String
    let method: HTTPMethod
    let body: Data?
    
    init(endpoint: String, method: HTTPMethod, body: Data? = nil) {
        self.endpoint = endpoint
        self.method = method
        self.body = body
    }
}
