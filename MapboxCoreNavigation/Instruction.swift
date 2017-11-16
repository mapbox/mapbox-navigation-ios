import Foundation

public struct Instruction: Equatable {
    
    public static func ==(lhs: Instruction, rhs: Instruction) -> Bool {
        return lhs.components == rhs.components
    }
    
    public var components: [Instruction.Component]
    
    public struct Component: Equatable {
        
        public static func ==(lhs: Instruction.Component, rhs: Instruction.Component) -> Bool {
            return lhs.text == rhs.text
                    && lhs.png == rhs.png
                    && lhs.roadCode == rhs.roadCode
                    && lhs.network == rhs.network
                    && lhs.number == rhs.number
        }
        
        public let text: String?
        public let png: String?
        public let roadCode: String?
        public let network: String?
        public let number: String?
        public let direction: String?
        public var prefix: String?
        
        public init(_ text: String?, png: String? = nil, roadCode: String? = nil, prefix: String? = nil) {
            self.text = text
            self.png = png
            self.roadCode = roadCode
            self.prefix = prefix
            
            guard let roadCode = roadCode else {
                self.network = nil
                self.number = nil
                self.direction = nil
                return
            }
            
            let components = roadCode.components(separatedBy: " ")
            if components.count == 2 || (components.count == 3 && ["North", "South", "East", "West", "Nord", "Sud", "Est", "Ouest", "Norte", "Sur", "Este", "Oeste"].contains(components[2])) {
                self.network = components[0]
                self.number = components[1]
                let containsDirection = components.count == 3
                self.direction = containsDirection ? components[2] : nil
            } else {
                self.network = nil
                self.number = nil
                self.direction = nil
            }
        }
    }
    
    public init(_ components: [Component]) {
        self.components = components
    }
    
    public init?(_ text: String?) {
        guard let text = text, !text.isEmpty else { return nil }
        self.init([Instruction.Component(text)])
    }
}
