import UIKit

extension UIImage {
    static let overviewImage = UIImage(
        named: "overview",
        in: .mapboxNavigation,
        compatibleWith: nil
    )!.withRenderingMode(.alwaysTemplate)

    static let previewOverviewImage = UIImage(
        named: "preview_overview",
        in: .mapboxNavigation,
        compatibleWith: nil
    )!.withRenderingMode(.alwaysTemplate)

    static let previewStartImage = UIImage(
        named: "start",
        in: .mapboxNavigation,
        compatibleWith: nil
    )!.withRenderingMode(.alwaysTemplate)

    static let volumeUpImage = UIImage(
        named: "volume_up",
        in: .mapboxNavigation,
        compatibleWith: nil
    )!.withRenderingMode(.alwaysTemplate)

    static let volumeOffImage = UIImage(
        named: "volume_off",
        in: .mapboxNavigation,
        compatibleWith: nil
    )!.withRenderingMode(.alwaysTemplate)

    static let feedbackImage = UIImage(
        named: "feedback",
        in: .mapboxNavigation,
        compatibleWith: nil
    )!.withRenderingMode(.alwaysTemplate)

    static let northUpImage = UIImage(
        named: "north-lock",
        in: .mapboxNavigation,
        compatibleWith: nil
    )!.withRenderingMode(.alwaysTemplate)

    static let recenterImage = UIImage(
        named: "recenter",
        in: .mapboxNavigation,
        compatibleWith: nil
    )!.withRenderingMode(.alwaysTemplate)

    static let followImage = UIImage(
        named: "follow",
        in: .mapboxNavigation,
        compatibleWith: nil
    )!.withRenderingMode(.alwaysTemplate)

    static let pinImage = UIImage(
        named: "pin",
        in: .mapboxNavigation,
        compatibleWith: nil
    )!.withRenderingMode(.alwaysTemplate)

    static let timeImage = UIImage(
        named: "time",
        in: .mapboxNavigation,
        compatibleWith: nil
    )!.withRenderingMode(.alwaysTemplate)

    static let locationImage = UIImage(
        named: "location",
        in: .mapboxNavigation,
        compatibleWith: nil
    )!.withRenderingMode(.alwaysTemplate)

    static let starImage = UIImage(
        named: "star",
        in: .mapboxNavigation,
        compatibleWith: nil
    )

    static let backImage = UIImage(
        named: "back",
        in: .mapboxNavigation,
        compatibleWith: nil
    )

    static let defaultMarkerImage = UIImage(
        named: "default_marker",
        in: .mapboxNavigation,
        compatibleWith: nil
    )!

    static let debugImage = UIImage(
        named: "debug",
        in: .mapboxNavigation,
        compatibleWith: nil
    )!.withRenderingMode(.alwaysTemplate)

    convenience init?(color: UIColor, size: CGSize = CGSize(width: 1.0, height: 1.0)) {
        let rect = CGRect(origin: .zero, size: size)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0.0)
        color.setFill()
        UIRectFill(rect)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        defer { UIGraphicsEndImageContext() }

        guard let cgImage = image?.cgImage else { return nil }
        self.init(cgImage: cgImage)
    }

    func withFontSize(
        font: UIFont,
        size: CGSize?
    ) -> UIImage {
        let maxHeight = size?.height ?? font.lineHeight * 2
        var constrainedSize = self.size
        constrainedSize.width = min(
            constrainedSize.width,
            constrainedSize.width * maxHeight / constrainedSize.height
        )

        constrainedSize.height = min(
            constrainedSize.height,
            maxHeight
        )

        let renderer = UIGraphicsImageRenderer(size: constrainedSize)
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: constrainedSize)
            draw(in: rect)
        }
    }

    func withCenteredText(
        _ text: String,
        color: UIColor,
        font: UIFont,
        size: CGSize? = nil
    ) -> UIImage {
        let maxHeight = size?.height ?? font.lineHeight * 2
        var constrainedSize = self.size
        constrainedSize.width = min(
            constrainedSize.width,
            constrainedSize.width * maxHeight / constrainedSize.height
        )

        constrainedSize.height = min(
            constrainedSize.height,
            maxHeight
        )

        let renderer = UIGraphicsImageRenderer(size: constrainedSize)
        return renderer.image { _ in
            let textStyle = NSMutableParagraphStyle()
            textStyle.alignment = .center

            let textFontAttributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: color,
                .paragraphStyle: textStyle,
            ]

            let rect = CGRect(origin: .zero, size: constrainedSize)
            draw(in: rect)

            (text as NSString).draw(
                in: rect.offsetBy(
                    dx: 0,
                    dy: (constrainedSize.height - font.lineHeight) / 2
                ).integral,
                withAttributes: textFontAttributes
            )
        }
    }

    func scale(to height: Double) -> UIImage {
        let ratio = height / size.height
        let newSize = CGSize(width: ratio * size.width, height: ratio * size.height)
        return UIGraphicsImageRenderer(size: newSize).image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    func scaled(to: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))

        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return scaledImage
    }

    func tint(_ tintColor: UIColor) -> UIImage {
        let imageSize = size
        let imageScale = scale
        let contextBounds = CGRect(origin: .zero, size: imageSize)

        UIGraphicsBeginImageContextWithOptions(imageSize, false, imageScale)

        defer { UIGraphicsEndImageContext() }

        UIColor.black.setFill()
        UIRectFill(contextBounds)
        draw(at: .zero)

        guard let imageOverBlack = UIGraphicsGetImageFromCurrentImageContext() else { return self }
        tintColor.setFill()
        UIRectFill(contextBounds)

        imageOverBlack.draw(at: .zero, blendMode: .multiply, alpha: 1)
        draw(at: .zero, blendMode: .destinationIn, alpha: 1)

        guard let finalImage = UIGraphicsGetImageFromCurrentImageContext() else { return self }

        return finalImage
    }

    /// Returns how much bytes the image takes in the memory.
    /// - important: Works reliably only for CGImage backed images.
    var memoryCost: Int {
        let costPerFrame: Int
        let framesCount: Int = if let images {
            images.count > 0 ? images.count : 1
        } else {
            1
        }

        if let cgImage {
            costPerFrame = cgImage.bytesPerRow * cgImage.height
        } else { // fallback to manual estimation
            costPerFrame = Int(scale * size.width) * Int(scale * size.height) * 4 // 4 for 4 RGBA colour components.
        }

        return costPerFrame * framesCount
    }
}
