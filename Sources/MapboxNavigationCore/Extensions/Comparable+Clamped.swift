extension Comparable {
    /// Returns new value clamped to the specified range.
    func clamped(to limits: ClosedRange<Self>) -> Self {
        var newValue = self
        newValue.clamp(to: limits)
        return newValue
    }

    /// Clamps `self` value to the specified range. Returns true if actual clamping was made.
    @discardableResult
    mutating func clamp(to limits: ClosedRange<Self>) -> Bool {
        guard self <= limits.upperBound else {
            self = limits.upperBound
            return true
        }

        guard self >= limits.lowerBound else {
            self = limits.lowerBound
            return true
        }

        return false
    }
}
