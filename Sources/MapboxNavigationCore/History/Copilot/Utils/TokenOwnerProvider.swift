import Foundation

enum TokenOwnerProvider {
    private struct JWTPayload: Decodable {
        var u: String
    }

    static func owner(of token: String) -> String? {
        guard let infoBase64String = token.split(separator: ".").dropFirst().first,
              let infoData = base64Decode(String(infoBase64String)),
              let info = try? JSONDecoder().decode(JWTPayload.self, from: infoData)
        else {
            assertionFailure("Failed to parse token.")
            return nil
        }
        return info.u
    }

    private static func base64Decode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let length = base64.lengthOfBytes(using: .utf8)
        let requiredLength = Int(4.0 * ceil(Double(length) / 4.0))
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            base64 += String(repeating: "=", count: paddingLength)
        }

        return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
    }
}
