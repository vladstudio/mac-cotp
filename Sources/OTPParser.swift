import Foundation

enum OTPParser {
    private static let keywords = [
        "code", "otp", "verification", "verify", "confirm",
        "password", "pin", "token", "login", "sign in",
        "security", "one-time", "one time", "2fa", "mfa",
        "passcode", "factor",
    ]

    // Digit patterns — ordered most common first
    private static let digitPatterns = [
        try! NSRegularExpression(pattern: #"\b\d{4,8}\b"#),                         // 123456
        try! NSRegularExpression(pattern: #"\b\d{2,4}[- ]\d{2,4}\b"#),             // 123 456, 123-456
        try! NSRegularExpression(pattern: #"\b\d{2,3}[- ]\d{2,3}[- ]\d{2,3}\b"#), // 12-34-56, 12 34 56
    ]

    // Alpha patterns
    private static let alphaPatterns = [
        try! NSRegularExpression(pattern: #"\b[A-Z]{4,8}\b"#),                      // FYOIQ
        try! NSRegularExpression(pattern: #"\b[A-Z]{2,4}[- ][A-Z]{2,4}\b"#),       // FYO-IQ
    ]

    static func detect(in text: String) -> String? {
        let lower = text.lowercased()
        guard keywords.contains(where: { lower.contains($0) }) else { return nil }

        let range = NSRange(text.startIndex..., in: text)

        for pattern in digitPatterns {
            if let code = firstValid(pattern, in: text, range: range, keep: \.isWholeNumber) {
                return code
            }
        }

        for pattern in alphaPatterns {
            if let code = firstValid(pattern, in: text, range: range, keep: \.isLetter) {
                return code
            }
        }

        return nil
    }

    private static func firstValid(
        _ regex: NSRegularExpression,
        in text: String,
        range: NSRange,
        keep: KeyPath<Character, Bool>
    ) -> String? {
        for match in regex.matches(in: text, range: range) {
            guard let r = Range(match.range, in: text) else { continue }
            let code = String(text[r].filter { $0[keyPath: keep] })
            guard (4...8).contains(code.count), !isFalsePositive(code) else { continue }
            return code
        }
        return nil
    }

    /// Filters out common false positives that look like OTPs but aren't.
    /// - Years (1900-2100): Prevents dates being detected as codes
    /// - Round thousands (1000, 2000, etc.): Prevents generic numbers being detected
    private static func isFalsePositive(_ s: String) -> Bool {
        guard let n = Int(s) else { return false }
        if (1900...2100).contains(n) { return true }
        if n % 1000 == 0 { return true }
        return false
    }
}
