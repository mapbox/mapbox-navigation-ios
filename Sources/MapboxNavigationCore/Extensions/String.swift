import CommonCrypto
import Foundation

extension String {
    typealias Replacement = (of: String, with: String)

    func byReplacing(_ replacements: [Replacement]) -> String {
        return replacements.reduce(self) { $0.replacingOccurrences(of: $1.of, with: $1.with) }
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

    // Adapted from https://github.com/raywenderlich/swift-algorithm-club/blob/master/Minimum%20Edit%20Distance/MinimumEditDistance.playground/Contents.swift
    public func minimumEditDistance(to word: String) -> Int {
        let fromWordCount = count
        let toWordCount = word.count

        guard !isEmpty else { return toWordCount }
        guard !word.isEmpty else { return fromWordCount }

        var matrix = [[Int]](repeating: [Int](repeating: 0, count: toWordCount + 1), count: fromWordCount + 1)

        // initialize matrix
        for index in 1...fromWordCount {
            // the distance of any first string to an empty second string
            matrix[index][0] = index
        }

        for index in 1...toWordCount {
            // the distance of any second string to an empty first string
            matrix[0][index] = index
        }

        // compute Levenshtein distance
        for (i, selfChar) in enumerated() {
            for (j, otherChar) in word.enumerated() {
                if otherChar == selfChar {
                    // substitution of equal symbols with cost 0
                    matrix[i + 1][j + 1] = matrix[i][j]
                } else {
                    // minimum of the cost of insertion, deletion, or substitution
                    // added to the already computed costs in the corresponding cells
                    matrix[i + 1][j + 1] = Swift.min(matrix[i][j] + 1, matrix[i + 1][j] + 1, matrix[i][j + 1] + 1)
                }
            }
        }
        return matrix[fromWordCount][toWordCount]
    }
}
