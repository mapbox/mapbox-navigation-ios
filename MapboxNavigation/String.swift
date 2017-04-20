import Foundation

extension String {
    var nonEmptyString: String? {
        return isEmpty ? nil : self
    }
    
    var wholeRange: NSRange {
        get {
            return NSRange(location: 0, length: characters.count)
        }
    }
}


extension String {
    typealias Replacement = (of: String, with: String)

    func byReplacing(_ replacements: [Replacement]) -> String {
        return replacements.reduce(self) { $0.replacingOccurrences(of: $1.of, with: $1.with) }
    }
    
    var addingXMLEscapes: String {
        return byReplacing([
            ("&", "&amp;"),
            ("<", "&lt;"),
            ("\"", "&quot;"),
            ("'", "&apos;")
            ])
    }
}

// From https://gist.github.com/joncardasis/7f09d1a55f3278d8ee5080e47653caff
extension String{
    private func min(numbers: Int...) -> Int {
        return numbers.reduce(numbers[0], {$0 < $1 ? $0 : $1})
    }
    
    func distanceFrom(string: String) -> Int{
        let x = Array(self.utf16) //convert to a unicode 16 format for comparison
        let y = Array(string.utf16)
        
        //Create the Levenshtein 2d matrix, which has an extra preceeding row and column
        var matrix = Array(repeating: [Int](repeating: 0, count: y.count + 1), count: x.count + 1)
        
        for i in 1...x.count{ //set rows (0,0 is already set from repeated value)
            matrix[i][0] = i
        }
        for j in 1...y.count{ //set columns
            matrix[0][j] = j
        }
        
        for row in 1...x.count{
            for col in 1...y.count {
                if(x[row-1] == y[col-1]){
                    matrix[row][col] = matrix[row-1][col-1] //Match
                }
                else{
                    matrix[row][col] = min(numbers:
                        matrix[row-1][col-1] + 1, //Subsitution
                        matrix[row-1][col] + 1, //Deletion
                        matrix[row][col-1] + 1 //Insertion
                    )
                }
            }
        }
        return matrix[x.count][y.count]
    }
}
