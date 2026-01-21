import Foundation

extension Error {
    var nsDescription: String {
        return (self as NSError).description
    }
}
