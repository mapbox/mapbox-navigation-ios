import Foundation

infix operator ≈: ComparisonPrecedence
infix operator ≉: ComparisonPrecedence

extension FloatingPoint {
    /**
     Returns a Boolean value indicating whether the two values are as equal as possible in floating-point representation.
     */
    static func ≈ (lhs: Self, rhs: Self) -> Bool {
        return rhs.nextDown...rhs.nextUp ~= lhs
    }

    /**
     Returns a Boolean value indicating whether the two values are not approximately equal.
     */
    static func ≉ (lhs: Self, rhs: Self) -> Bool {
        return !(lhs ≈ rhs)
    }
}

extension JSONSerialization {
    /**
     Returns a Boolean value indicating whether the given JSON-representable objects are equal to one another.

     If anything in the objects is not JSON-representable, this method returns false.

     - parameter approximate: True to allow for floating-point error when comparing two Doubles.
     - returns: True if the two objects are equal to one another.
     */
    static func objectsAreEqual(_ lhs: Any?, _ rhs: Any?, approximate: Bool) -> Bool {
        if let _ = try? assertObjectsAreEqual(lhs, rhs, approximate: approximate) {
            return true
        } else {
            return false
        }
    }

    static func assertObjectsAreEqual(_ lhs: Any?, _ rhs: Any?, approximate: Bool) throws -> Bool {
        enum EqualityError: Error {
            case notEqual
        }

        if lhs == nil || rhs == nil {
            guard lhs == nil, rhs == nil else {
                throw EqualityError.notEqual
            }
            return true
        } else if let lhs = lhs as? Bool, let rhs = rhs as? Bool {
            guard lhs == rhs else {
                throw EqualityError.notEqual
            }
            return true
        } else if let lhs = lhs as? Int, let rhs = rhs as? Int {
            guard lhs == rhs else {
                throw EqualityError.notEqual
            }
            return true
        } else if let lhs = lhs as? Double, let rhs = rhs as? Double {
            guard approximate ? (lhs ≈ rhs) : (lhs == rhs) else {
                throw EqualityError.notEqual
            }
            return true
        } else if let lhs = lhs as? String, let rhs = rhs as? String {
            guard lhs == rhs else {
                throw EqualityError.notEqual
            }
            return true
        } else if let lhs = lhs as? [Any?], let rhs = rhs as? [Any?] {
            guard lhs.count == rhs.count,
                  lhs.elementsEqual(rhs, by: { objectsAreEqual($0, $1, approximate: approximate) })
            else {
                throw EqualityError.notEqual
            }
            return true
        } else if let lhs = lhs as? [String: Any?], let rhs = rhs as? [String: Any?] {
            if lhs.count != rhs.count {
                throw EqualityError.notEqual
            }
            _ = try lhs.merging(rhs, uniquingKeysWith: { lhs, rhs -> Any? in
                if !objectsAreEqual(lhs, rhs, approximate: approximate) {
                    throw EqualityError.notEqual
                }
                return lhs
            })
            return true
        } else {
            throw EqualityError.notEqual
        }
    }
}
