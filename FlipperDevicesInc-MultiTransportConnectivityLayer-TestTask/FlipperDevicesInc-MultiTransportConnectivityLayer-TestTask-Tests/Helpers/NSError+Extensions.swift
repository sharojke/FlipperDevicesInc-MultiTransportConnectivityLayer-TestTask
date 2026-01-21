import Foundation

extension NSError {
    static var anyError: NSError {
        return NSError(domain: "Any", code: .zero)
    }
    
    static func create(_ description: String) -> NSError {
        NSError(domain: description, code: .zero)
    }
}
