import Foundation

// swiftlint:disable no_magic_numbers

extension Duration {
    static var shortSleep: Self { .milliseconds(500) }
    static var mediumSleep: Self { .seconds(1) }
    static var longSleep: Self { .seconds(2) }
    static var veryLongSleep: Self { .seconds(3) }
}

// swiftlint:enable no_magic_numbers
