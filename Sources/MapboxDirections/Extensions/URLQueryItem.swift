import Foundation

extension [URLQueryItem] {
    var duplicatedNames: Set<String> {
        var seen = Set<String>()
        var duplicates = Set<String>()

        for param in self {
            if seen.contains(param.name) {
                duplicates.insert(param.name)
            } else {
                seen.insert(param.name)
            }
        }
        return duplicates
    }

    mutating func override(with params: [URLQueryItem]) {
        let names = Set(params.map(\.name))
        removeAll { names.contains($0.name) }
        append(contentsOf: params)
    }
}
