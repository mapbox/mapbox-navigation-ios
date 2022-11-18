import MapboxCoreNavigation

/**
 Customization options for the navigation preview user experience in a `PreviewViewController`.
 */
public struct PreviewOptions {
    
    /**
     The styles that the `PreviewViewController`'s internal `StyleManager` object can select from
     for display.
     
     If this property is set to `nil`, a `DayStyle` and a `NightStyle` are created to be used as the
     `PreviewViewController`'s styles. This property is set to `nil` by default.
     */
    public private(set) var styles: [Style]? = nil
    
    /**
     Initializes `PreviewOptions` that is used as a configuration for the `PreviewViewController`.
     
     - parameter styles: The user interface styles that are available for display.
     */
    public init(styles: [Style]? = nil) {
        self.styles = styles
    }
}
