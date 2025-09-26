import MapboxNavigationNative_Private

extension RouteIdentifier {
    public static func mock(
        uuid: String = "",
        index: UInt32 = 0
    ) -> Self {
        self.init(
            uuid: uuid,
            index: index
        )
    }
}
