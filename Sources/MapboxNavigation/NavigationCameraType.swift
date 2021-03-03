/**
 Possible types of `NavigationCamera`.
 */
public enum NavigationCameraType {
    
    /**
     When such type is used `CameraOptions` will be optimized
     specifically for CarPlay devices.
     */
    case headUnit
    
    /**
     Type, which is used for iPhone/iPad.
     */
    case mobile
}
