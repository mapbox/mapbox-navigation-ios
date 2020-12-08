extension UIColor {
    
    /**
     Returns a Boolean value indicating whether this instance is equal to the given `UIColor` value.
     Prior to comparison given `UIColor.cgColor.colorSpace` value will be converted to match the one which is used in current instance.
     */
    func isEqual(_ color: UIColor) -> Bool {
        guard let colorSpace = self.cgColor.colorSpace else { return false }
        guard let convertedColor = color.cgColor.converted(to: colorSpace, intent: .absoluteColorimetric, options: nil) else { return false }
        
        return self.cgColor == convertedColor
    }
}
