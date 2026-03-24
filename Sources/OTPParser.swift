import Foundation

enum OTPParser {
    private static let keywords = [
        "code", "otp", "verification", "verify", "confirm",
        "password", "pin", "token", "login", "sign in",
        "security", "one-time", "one time", "2fa", "mfa",
        "passcode", "factor",
    ]

    private static let numericPattern = try! NSRegularExpression(pattern: #"\b(\d{4,8})\b"#)
    private static let splitPattern = try! NSRegularExpression(pattern: #"\b(\d{3,4})[- ](\d{3,4})\b"#)
    private static let alphaPattern = try! NSRegularExpression(pattern: #"\b([A-Z]{4,8})\b"#)

    static func detect(in text: String) -> String? {
        let lower = text.lowercased()
        guard keywords.contains(where: { lower.contains($0) }) else { return nil }

        let range = NSRange(text.startIndex..., in: text)

        // 4-8 digit code: "123456"
        if let code = firstValid(numericPattern, in: text, range: range) { return code }

        // Split code: "123-456" or "123 456"
        if let match = splitPattern.firstMatch(in: text, range: range),
           let r1 = Range(match.range(at: 1), in: text),
           let r2 = Range(match.range(at: 2), in: text) {
            let combined = String(text[r1]) + String(text[r2])
            if !isFalsePositive(combined) { return combined }
        }

        // Uppercase alpha code: "FYOIQ"
        if let code = firstValid(alphaPattern, in: text, range: range) { return code }

        return nil
    }

    private static func firstValid(_ regex: NSRegularExpression, in text: String, range: NSRange) -> String? {
        for match in regex.matches(in: text, range: range) {
            guard let r = Range(match.range(at: 1), in: text) else { continue }
            let code = String(text[r])
            if !isFalsePositive(code) { return code }
        }
        return nil
    }

    private static func isFalsePositive(_ s: String) -> Bool {
        guard let n = Int(s) else { return false }
        if (1900...2100).contains(n) { return true }
        if n % 1000 == 0 { return true }
        return false
    }
}
