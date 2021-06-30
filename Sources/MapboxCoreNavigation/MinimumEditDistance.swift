import Foundation

extension String {
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
