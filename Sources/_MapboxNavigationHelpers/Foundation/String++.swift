extension String {
    public func firstCapitalized() -> String {
        prefix(1).uppercased() + dropFirst()
    }
}
