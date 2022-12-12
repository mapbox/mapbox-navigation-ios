import Foundation

// MARK: - Type declaration
public struct BreakingChangesReport: Equatable {
    public struct Category: Equatable {
        public init(name: String, changes: [String]) {
            self.name = name
            self.changes = changes
        }

        public let name: String
        public var changes: [String]
    }

    // MARK: - Stored Vars
    public let moduleName: String
    public var categories: [Category]

    public init(moduleName: String, swiftApiDigesterOutput: String) throws {
        self.moduleName = moduleName
        let lines = swiftApiDigesterOutput.split { $0.isNewline }

        let categoryRegex = try NSRegularExpression(pattern: "/\\*\\s*(.*)\\s*\\*/")

        var categories: [Category] = []
        var currentCategory: Category?

        for line in lines {
            let input = String(line)
            let categoryMatches = categoryRegex.matches(in: input, range: NSRange(input.startIndex..., in: input))

            if let match = categoryMatches.first {
                let categoryName = (input as NSString).substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
                if let currentCategory {
                    categories.append(currentCategory)
                }
                currentCategory = .init(name: categoryName, changes: [])
            }
            else if currentCategory != nil {
                currentCategory?.changes.append(input)
            }
        }

        if let currentCategory {
            categories.append(currentCategory)
        }

        self.categories = categories
    }

    public init(moduleName: String, entries: [Category]) {
        self.moduleName = moduleName
        self.categories = entries
    }

    // MARK: - Formatting

    public func formatted(to outputFormat: OutputFormat) -> String {
        switch outputFormat {
        case .gitHubMarkdown:
            return formattedToGithubMarkdown()
        }
    }

    /// Formats categories to GitHub Markdown string using tables.
    private func formattedToGithubMarkdown() -> String {
        if isEmpty() {
            return "**API compatibility report for \(moduleName):** 🟢"
        }

        var markdown = "## API compatibility report for \(moduleName): 🔴\n\n"

        for category in categories where !category.changes.isEmpty {
            markdown.append("#### \(category.name)\n\n")

            for change in category.changes {
                markdown.append("* \(change)\n")
            }
        }

        return markdown
    }

    // MARK: - Other

    public func isEmpty() -> Bool {
        categories.allSatisfy { category in
            category.changes.isEmpty
        }
    }
}
