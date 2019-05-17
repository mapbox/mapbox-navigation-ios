enum CardFont: String {
    case regular
    case bold
    
    static func create(_ type: CardFont, with size: CGFloat) -> UIFont! {
        return type == .bold ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size)
    }
}

struct CardFontType {
    static let regular: String = "FontSystem-Regular"
    static let bold: String =  "FontSystem-Bold"
}
