import CommonCrypto
import Foundation

extension String {
    /// Check if the current string is empty. If the string is empty, `nil` is returned, otherwise, the string is
    /// returned.
    public var nonEmptyString: String? {
        return isEmpty ? nil : self
    }

    /// Returns the SHA256 hash of the string.
    var sha256: String {
        let length = Int(CC_SHA256_DIGEST_LENGTH)
        let digest = utf8CString.withUnsafeBufferPointer { body -> [UInt8] in
            var digest = [UInt8](repeating: 0, count: length)
            CC_SHA256(body.baseAddress, CC_LONG(lengthOfBytes(using: .utf8)), &digest)
            return digest
        }
        return digest.lazy.map { String(format: "%02x", $0) }.joined()
    }
}
