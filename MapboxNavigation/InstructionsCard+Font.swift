/// :nodoc:
enum CardFont: String {
    case regular
    case bold
    
    static func create(_ type: CardFont, with size: CGFloat) -> UIFont! {
        let font = type == .bold ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size)
        return font.adjustedFont
    }
}

/// :nodoc:
struct CardFontType {
    static let regular: String = "FontSystem-Regular"
    static let bold: String =  "FontSystem-Bold"
}
