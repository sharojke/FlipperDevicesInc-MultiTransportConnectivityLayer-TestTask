import Foundation
import Synchronization

final class MulticastAsyncStream<T: Sendable>: Sendable {
    private let continuations = Mutex<[AsyncStream<T>.Continuation]>([])

    func stream() -> AsyncStream<T> {
        AsyncStream { continuation in
            continuations.withLock { $0.append(continuation) }
        }
    }

    func yield(_ value: T) {
        continuations.withLock { continuations in
            continuations.forEach { $0.yield(value) }
        }
    }
}
