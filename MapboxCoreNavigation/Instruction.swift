import Foundation

public struct Instruction {
    
    public let components: [Instruction.Component]
    
    public struct Component {
        public let text: String?
        public let png: String?
        public let roadCode: String?
        public let network: String?
        public let number: String?
        
        public var shieldKey: String? {
            guard let roadCode = roadCode else { return nil }
            let components = roadCode.components(separatedBy: " ")
            return "\(components[0])\(components[1])"
        }
        
        public init(_ text: String?, png: String? = nil, roadCode: String? = nil) {
            self.text = text
            self.png = png
            self.roadCode = roadCode
            
            guard let roadCode = roadCode else {
                self.network = nil
                self.number = nil
                return
            }
            
            let components = roadCode.components(separatedBy: " ")
            if components.count == 2 || (components.count == 3 && ["North", "South", "East", "West", "Nord", "Sud", "Est", "Ouest", "Norte", "Sur", "Este", "Oeste"].contains(components[2])) {
                self.network = components[0]
                self.number = components[1]
            } else {
                self.network = nil
                self.number = nil
            }
        }
    }
    
    public init(_ components: [Component]) {
        self.components = components
    }
}
