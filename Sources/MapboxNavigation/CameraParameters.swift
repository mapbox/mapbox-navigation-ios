import Foundation

struct CameraParameters: OptionSet {
    
    let rawValue: Int
    
    static let center = CameraParameters(rawValue: 1 << 0)
    static let zoom = CameraParameters(rawValue: 1 << 1)
    static let bearing = CameraParameters(rawValue: 1 << 2)
    static let pitch = CameraParameters(rawValue: 1 << 3)
}
