import Foundation

protocol AnyError: Error, CustomStringConvertible {}

extension AnyError {
    var description: String {
        "\(Self.self)"
    }
}
