import MapboxNavigationNative

protocol NativeNavigatorProvider {
    static var navigator: MapboxNavigationNative.Navigator { get }
}

extension Navigator: NativeNavigatorProvider {
    static var navigator: MapboxNavigationNative.Navigator {
        return Self.shared.navigator
    }
}
