import _MapboxNavigationHelpers
import SwiftUI
import UIKit

protocol Renderer {
    func draw(in context: CGContext, for traitCollection: UITraitCollection)
}

extension Renderer {
    func image(
        for traitCollection: UITraitCollection,
        imageSize: CGSize
    ) -> UIImage {
        let rendererFormat = UIGraphicsImageRendererFormat(for: traitCollection)
        rendererFormat.opaque = false
        let renderer = UIGraphicsImageRenderer(size: imageSize, format: rendererFormat)

        return renderer.image { uiContext in
            draw(in: uiContext.cgContext, for: traitCollection)
        }
    }

    /// Renders visual instruction for each `ColorSchema` variant and returns `UIImage` which is backed by UIImageAsset.
    func imageAsset(
        for traitCollection: UITraitCollection,
        imageSize: CGSize
    ) -> UIImage {
        let asset = UIImageAsset()

        ColorScheme
            .allCases
            .map { colorSchema in
                UITraitCollection(traitsFrom: [
                    traitCollection,
                    colorSchema.traitCollection,
                ])
            }
            .forEach { traitCollection in
                with(image(for: traitCollection, imageSize: imageSize)) {
                    asset.register($0, with: traitCollection)
                }
            }

        return asset.image(with: traitCollection)
    }
}

extension ColorScheme {
    fileprivate var traitCollection: UITraitCollection {
        .init(userInterfaceStyle: .init(self))
    }
}
