# Styling

You can customize the appearance in order to blend in with the rest of your app.

```swift
let style = Style()
style.maneuverViewHeight = 80
style.primaryTextColor = .black
style.headerBackgroundColor = .white
style.cellTitleLabelFont = .preferredFont(forTextStyle: .headline)
style.apply()
```

Or for a specific system trait in an interface’s environment.
For instance only when being used on an iPad.

```swift
let style = Style(traitCollection: UITraitCollection(userInterfaceIdiom: .pad))
style.cellTitleLabelFont = .preferredFont(forTextStyle: .title1)
style.apply()
```
