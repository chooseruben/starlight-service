
import Foundation

enum PhoneNumberFormatter {

    static func format(_ input: String) -> String {
        var digits = input.filter { $0.isNumber }

        // Convert US country-code numbers to 10 digits
        if digits.count == 11 && digits.hasPrefix("1") {
            digits.removeFirst()
        }

        // Preserve unusual or international phone numbers
        guard digits.count <= 10 else {
            return input
        }

        if digits.count <= 3 {
            return digits
        }

        if digits.count <= 6 {
            let area = digits.prefix(3)
            let remaining = digits.dropFirst(3)
            return "(\(area)) \(remaining)"
        }

        let area = digits.prefix(3)
        let middle = digits.dropFirst(3).prefix(3)
        let last = digits.dropFirst(6)

        return "(\(area)) \(middle)-\(last)"
    }

    static func dialable(_ input: String) -> String {
        let digits = input.filter { $0.isNumber }
        return input.hasPrefix("+") ? "+" + digits : digits
    }
}
