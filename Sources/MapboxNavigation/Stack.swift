import Foundation

protocol Stackable {
    
    associatedtype Element
    
    var count: Int { get }
    
    func peek() -> Element?
    
    mutating func push(_ element: Element)
    
    @discardableResult mutating func pop() -> Element?
}

struct Stack<Element>: Stackable {
    
    var elements = [Element]()
    
    var count: Int {
        elements.count
    }
    
    func peek() -> Element? {
        return elements.last
    }
    
    mutating func push(_ element: Element) {
        elements.append(element)
    }
    
    @discardableResult mutating func pop() -> Element? {
        elements.popLast()
    }
    
    mutating func popAllExceptFirst() {
        guard let firstElement = elements.first else {
            return
        }
        
        elements = [firstElement]
    }
}
