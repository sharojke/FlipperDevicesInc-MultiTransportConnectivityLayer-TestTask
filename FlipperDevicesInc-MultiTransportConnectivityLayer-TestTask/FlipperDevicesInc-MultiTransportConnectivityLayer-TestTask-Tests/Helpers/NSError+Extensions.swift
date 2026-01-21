import Foundation

extension NSError {
    static var anyError: NSError {
        return NSError(domain: "Any", code: 123)
    }
}
