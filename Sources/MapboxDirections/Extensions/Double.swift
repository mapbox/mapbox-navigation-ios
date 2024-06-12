extension Double {
    func rounded(to precision: Double) -> Double {
        return (self * precision).rounded() / precision
    }
}
