import Foundation
import CommonCrypto

let ISO8601Formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
}()

extension String {
    var ISO8601Date: Date? {
        return ISO8601Formatter.date(from: self)
    }
    
    /**
     Check if the current string is empty. If the string is empty, `nil` is returned, otherwise, the string is returned.
     */
    public var nonEmptyString: String? {
        return isEmpty ? nil : self
    }
    
    typealias Replacement = (of: String, with: String)
    
    func byReplacing(_ replacements: [Replacement]) -> String {
        return replacements.reduce(self) { $0.replacingOccurrences(of: $1.of, with: $1.with) }
    }
    
    /**
     Returns the MD5 hash of the string.
     */
    var md5: String {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let digest = utf8CString.withUnsafeBufferPointer { (body) -> [UInt8] in
            var digest = [UInt8](repeating: 0, count: length)
            CC_MD5(body.baseAddress, CC_LONG(lengthOfBytes(using: .utf8)), &digest)
            return digest
        }
        return digest.lazy.map { String(format: "%02x", $0) }.joined()
    }
}
