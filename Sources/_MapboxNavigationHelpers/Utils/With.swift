/// Returns `value` after calling `modify` on it.
@discardableResult
@inlinable
public func with<Value>(_ value: Value, modify: (inout Value) throws -> Void) rethrows -> Value {
    var value = value
    try modify(&value)
    return value
}
