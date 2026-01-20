import Foundation

extension Task where Success == Never, Failure == Never {
    static func shortSleep() async throws {
        try await Task.sleep(for: .shortSleep)
    }
    
    static func mediumSleep() async throws {
        try await Task.sleep(for: .mediumSleep)
    }
    
    static func longSleep() async throws {
        try await Task.sleep(for: .longSleep)
    }
    
    static func veryLongSleep() async throws {
        try await Task.sleep(for: .veryLongSleep)
    }
}
