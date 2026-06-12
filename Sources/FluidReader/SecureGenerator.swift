import Foundation
import Security

enum SecureGenerator {
    static let passwordAlphabet = "ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#$%^&*()-_=+[]{}"
    static let pinAlphabet = "0123456789"

    static func strongPassword(length: Int = 24) -> String {
        randomString(length: length, alphabet: passwordAlphabet)
    }

    static func pin(length: Int = 6) -> String {
        randomString(length: length, alphabet: pinAlphabet)
    }

    static func hexToken(byteCount: Int = 16) -> String {
        hexToken(from: randomBytes(count: byteCount))
    }

    static func urlToken(byteCount: Int = 24) -> String {
        urlToken(from: randomBytes(count: byteCount))
    }

    static func string(from bytes: [UInt8], alphabet: String, length: Int) -> String {
        guard length > 0, !alphabet.isEmpty else { return "" }

        // Rejection sampling, matching randomString: discard bytes outside the
        // largest multiple of the alphabet size so no character is more likely
        // than another (avoids modulo bias).
        let characters = Array(alphabet)
        let bucketSize = characters.count
        let upperBound = 256 - (256 % bucketSize)
        var output = ""

        for byte in bytes {
            guard Int(byte) < upperBound else { continue }
            output.append(characters[Int(byte) % bucketSize])
            if output.count == length {
                break
            }
        }

        return output
    }

    static func hexToken(from bytes: [UInt8]) -> String {
        bytes.map { byte in
            String(format: "%02x", byte)
        }.joined()
    }

    static func urlToken(from bytes: [UInt8]) -> String {
        Data(bytes)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func randomString(length: Int, alphabet: String) -> String {
        guard length > 0, !alphabet.isEmpty else { return "" }

        let characters = Array(alphabet)
        let bucketSize = characters.count
        let upperBound = 256 - (256 % bucketSize)
        var output = ""

        while output.count < length {
            for byte in randomBytes(count: max(16, length)) {
                guard Int(byte) < upperBound else { continue }
                output.append(characters[Int(byte) % bucketSize])
                if output.count == length {
                    return output
                }
            }
        }

        return output
    }

    private static func randomBytes(count: Int) -> [UInt8] {
        guard count > 0 else { return [] }

        var bytes = [UInt8](repeating: 0, count: count)
        let status = bytes.withUnsafeMutableBytes { buffer in
            guard let baseAddress = buffer.baseAddress else {
                return errSecParam
            }
            return SecRandomCopyBytes(kSecRandomDefault, count, baseAddress)
        }

        if status == errSecSuccess {
            return bytes
        }

        return (0..<count).map { _ in UInt8.random(in: UInt8.min...UInt8.max) }
    }
}
