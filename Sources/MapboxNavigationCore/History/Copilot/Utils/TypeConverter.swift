import Foundation

struct TypeConverter {
    func convert<ToType>(
        from fromType: some Any,
        to toType: ToType.Type,
        file: String = #file,
        function: String = #function,
        line: Int = #line,
        column: Int = #column
    ) throws -> ToType {
        guard let convertedValue = fromType as? ToType else {
            throw NSError(
                domain: "com.mapbox.copilot.developerError.failedTypeConversion",
                code: -1,
                userInfo: [
                    "explanation": "Failed to convert \(String(describing: fromType)) to \(toType)",
                    "file": file,
                    "function": function,
                    "line": "\(line)",
                    "column": "\(column)",
                ]
            )
        }
        return convertedValue
    }
}
