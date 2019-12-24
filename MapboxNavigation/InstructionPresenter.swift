import UIKit
import MapboxDirections

protocol InstructionPresenterDataSource: class {
    var availableBounds: (() -> CGRect)! { get }
    var font: UIFont! { get }
    var textColor: UIColor! { get }
    var shieldHeight: CGFloat { get }
}

typealias DataSource = InstructionPresenterDataSource

class InstructionPresenter {
    private let instruction: VisualInstruction
    private weak var dataSource: DataSource?

    required init(_ instruction: VisualInstruction, dataSource: DataSource, imageRepository: ImageRepository = .shared, downloadCompletion: ShieldDownloadCompletion?) {
        self.instruction = instruction
        self.dataSource = dataSource
        self.imageRepository = imageRepository
        self.onShieldDownload = downloadCompletion
    }

    typealias ImageDownloadCompletion = (UIImage?) -> Void
    typealias ShieldDownloadCompletion = (NSAttributedString) -> ()
    
    let onShieldDownload: ShieldDownloadCompletion?

    private let imageRepository: ImageRepository
    
    func attributedText() -> NSAttributedString {
        let string = NSMutableAttributedString()
        fittedAttributedComponents().forEach { string.append($0) }
        return string
    }
    
    func fittedAttributedComponents() -> [NSAttributedString] {
        guard let source = self.dataSource else { return [] }
        var attributedPairs = self.attributedPairs(for: instruction, dataSource: source, imageRepository: imageRepository, onImageDownload: completeShieldDownload)
        let availableBounds = source.availableBounds()
        let totalWidth: CGFloat = attributedPairs.attributedStrings.map { $0.size() }.reduce(.zero, +).width
        let stringFits = totalWidth <= availableBounds.width
        
        guard !stringFits else { return attributedPairs.attributedStrings }
        
        typealias IndexedTextRepresentation = (Array<VisualInstruction.Component>.Index, VisualInstruction.Component.TextRepresentation)
        let textRepresentations: [IndexedTextRepresentation]  = attributedPairs.components.enumerated().compactMap { (idx, elem) in
            if case let VisualInstruction.Component.text(representation) = elem {
                return (idx, representation)
            }
            return nil
        }
        
        let sorted = textRepresentations.sorted { first, second in
            let firstPriority = first.1.abbreviationPriority ?? Int.max
            let secondPriority = second.1.abbreviationPriority ?? Int.max
            
            return firstPriority < secondPriority
        }

        for (index, representation) in sorted {
            let isFirst = index == 0
            let joinChar = isFirst ? "" : " "
            guard let abbreviation = representation.abbreviation else { continue }
            
            attributedPairs.attributedStrings[index] = NSAttributedString(string: joinChar + abbreviation, attributes: attributes(for: source))
            let newWidth: CGFloat = attributedPairs.attributedStrings.map { $0.size() }.reduce(.zero, +).width
            
            if newWidth <= availableBounds.width {
                break
            }
        }
        
        return attributedPairs.attributedStrings
    }
    
    typealias AttributedInstructionComponents = (components: [VisualInstruction.Component], attributedStrings: [NSAttributedString])
    
    func attributedPairs(for instruction: VisualInstruction, dataSource: DataSource, imageRepository: ImageRepository, onImageDownload: @escaping ImageDownloadCompletion) -> AttributedInstructionComponents {
        let components = instruction.components
        var strings: [NSAttributedString] = []
        var processedComponents: [VisualInstruction.Component] = []
        
        for (index, component) in components.enumerated() {
            let isFirst = index == 0
            let joinChar = isFirst ? "" : " "
            let joinString = NSAttributedString(string: joinChar, attributes: attributes(for: dataSource))
            let initial = NSAttributedString()
            
            
            
            //This is the closure that builds the string.
            let build: (_: VisualInstruction.Component, _: [NSAttributedString]) -> Void = { (component, attributedStrings) in
                processedComponents.append(component)
                strings.append(attributedStrings.reduce(initial, +))
            }
            let isShield: (_ key: VisualInstruction.Component?) -> Bool = { (component) in
                guard let key = component?.cacheKey else { return false }
                return imageRepository.cachedImageForKey(key) != nil
            }
            
            let componentBefore = components.component(before: component)
            let componentAfter  = components.component(after: component)
            
            switch component {
            //Throw away exit components. We know this is safe because we know that if there is an exit component,
            //  there is an exit code component, and the latter contains the information we care about.
            case .exit:
                continue
                
            //If we have a exit, in the first two components, lets handle that.
            case let .exitCode(representation) where 0...1 ~= index:
                guard let exitString = self.attributedString(forExitRepresentation: representation, maneuverDirection: instruction.maneuverDirection!, dataSource: dataSource, cacheKey: component.cacheKey!) else { fallthrough }
                build(component, [exitString])
                
            //if it's a delimiter, skip it if it's between two shields.
            case .delimiter where isShield(componentBefore) && isShield(componentAfter):
                continue
                
            //If we have an icon component, lets turn it into a shield.
            case let .image(imageRepresentation, textRepresentation):
                if let shieldString = attributedString(forShieldComponent: imageRepresentation, repository: imageRepository, dataSource: dataSource, cacheKey: component.cacheKey!, onImageDownload: onImageDownload) {
                    build(component, [joinString, shieldString])
                } else if let genericShieldString = attributedString(forGenericShield: textRepresentation, dataSource: dataSource, cacheKey: component.cacheKey!) {
                    build(component, [joinString, genericShieldString])
                } else {
                    fallthrough
                }
                
            case let .text(textRepresentation), let .delimiter(textRepresentation):
                let componentString = NSAttributedString(string: textRepresentation.text, attributes: attributes(for: dataSource))
                build(component, [joinString, componentString])
            
            default:
                continue
            }
        }
        
        assert(processedComponents.count == strings.count, "The number of processed components must match the number of attributed strings")
        return (components: processedComponents, attributedStrings: strings)
    }

    func attributedString(forExitRepresentation representation: VisualInstruction.Component.TextRepresentation, maneuverDirection: ManeuverDirection, dataSource: DataSource, cacheKey: String) -> NSAttributedString? {
        let exitCode = representation.text
        let side: ExitSide = maneuverDirection == .left ? .left : .right
        guard let exitString = exitShield(side: side, text: exitCode, dataSource: dataSource, cacheKey: cacheKey) else { return nil }
        return exitString
    }
    
    func attributedString(forGenericShield representation: VisualInstruction.Component.TextRepresentation, dataSource: DataSource, cacheKey: String) -> NSAttributedString? {
        let text = representation.text
        return genericShield(text: text, dataSource: dataSource, cacheKey: cacheKey)
    }
    
    func attributedString(forShieldComponent shield: VisualInstruction.Component.ImageRepresentation, repository:ImageRepository, dataSource: DataSource, cacheKey: String, onImageDownload: @escaping ImageDownloadCompletion) -> NSAttributedString? {
        //If we have the shield already cached, use that.
        if let cachedImage = repository.cachedImageForKey(cacheKey) {
            return attributedString(withFont: dataSource.font, shieldImage: cachedImage)
        }
        
        // Let's download the shield
        shieldImageForComponent(representation: shield, in: repository, cacheKey: cacheKey, completion: onImageDownload)
        
        //Return nothing in the meantime, triggering downstream behavior (generic shield or text)
        return nil
    }
    
    
    private func shieldImageForComponent(representation: VisualInstruction.Component.ImageRepresentation, in repository: ImageRepository, cacheKey: String, completion: @escaping ImageDownloadCompletion) {
        guard let imageURL = representation.imageURL(scale: VisualInstruction.Component.scale, format: .png) else { return }
        

        repository.imageWithURL(imageURL, cacheKey: cacheKey, completion: completion )
    }

    private func attributes(for dataSource: InstructionPresenterDataSource) -> [NSAttributedString.Key: Any] {
        return [.font: dataSource.font as Any, .foregroundColor: dataSource.textColor as Any]
    }

    private func attributedString(withFont font: UIFont, shieldImage: UIImage) -> NSAttributedString {
        let attachment = ShieldAttachment()
        attachment.font = font
        attachment.image = shieldImage
        return NSAttributedString(attachment: attachment)
    }
    
    private func genericShield(text: String, dataSource: DataSource, cacheKey: String) -> NSAttributedString? {
        let additionalKey = GenericRouteShield.criticalHash(dataSource: dataSource)
        let attachment = GenericShieldAttachment()
        
        let key = [cacheKey, additionalKey].joined(separator: "-")
        if let image = imageRepository.cachedImageForKey(key) {
            attachment.image = image
        } else {
            let view = GenericRouteShield(pointSize: dataSource.font.pointSize, text: text)
            view.foregroundColor = dataSource.textColor
            guard let image = takeSnapshot(on: view) else { return nil }
            imageRepository.storeImage(image, forKey: key, toDisk: false)
            attachment.image = image
        }
        
        attachment.font = dataSource.font

        return NSAttributedString(attachment: attachment)
    }
    
    private func exitShield(side: ExitSide = .right, text: String, dataSource: DataSource, cacheKey: String) -> NSAttributedString? {
        let additionalKey = ExitView.criticalHash(side: side, dataSource: dataSource)
        let attachment = ExitAttachment()

        let key = [cacheKey, additionalKey].joined(separator: "-")
        if let image = imageRepository.cachedImageForKey(key) {
            attachment.image = image
        } else {
            let view = ExitView(pointSize: dataSource.font.pointSize, side: side, text: text)
            view.foregroundColor = dataSource.textColor
            guard let image = takeSnapshot(on: view) else { return nil }
            imageRepository.storeImage(image, forKey: key, toDisk: false)
            attachment.image = image
        }
        
        attachment.font = dataSource.font
        
        return NSAttributedString(attachment: attachment)
    }
    
    private func completeShieldDownload(_ image: UIImage?) {
        guard image != nil else { return }
        //We *must* be on main thread here, because attributedText() looks at object properties only accessible on main thread.
        DispatchQueue.main.async {
            self.onShieldDownload?(self.attributedText()) //FIXME: Can we work with the image directly?
        }
    }
    
    private func takeSnapshot(on view: UIView) -> UIImage? {
        let window: UIWindow
        if let hostView = dataSource as? UIView, let hostWindow = hostView.window {
            window = hostWindow
        } else {
            window = UIApplication.shared.delegate!.window!!
        }
        
        // Temporarily add the view to the view hierarchy for UIAppearance to work its magic.
        window.addSubview(view)
        let image = view.imageRepresentation
        view.removeFromSuperview()
        return image
    }
}

protocol ImagePresenter: TextPresenter {
    var image: UIImage? { get }
}

protocol TextPresenter {
    var text: String? { get }
    var font: UIFont { get }
}

class ImageInstruction: NSTextAttachment, ImagePresenter {
    var font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
    var text: String?
    
    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        guard let image = image else {
            return super.attachmentBounds(for: textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)
        }
        let yOrigin = (font.capHeight - image.size.height).rounded() / 2
        return CGRect(x: 0, y: yOrigin, width: image.size.width, height: image.size.height)
    }
}

class TextInstruction: ImageInstruction {}
class ShieldAttachment: ImageInstruction {}
class GenericShieldAttachment: ShieldAttachment {}
class ExitAttachment: ImageInstruction {}
class RoadNameLabelAttachment: TextInstruction {
    var scale: CGFloat?
    var color: UIColor?

    var compositeImage: UIImage? {
        guard let image = image, let text = text, let color = color, let scale = scale else {
            return nil
        }
        
        var currentImage: UIImage?
        let textHeight = font.lineHeight
        let pointY = (image.size.height - textHeight) / 2
        currentImage = image.insert(text: text as NSString, color: color, font: font, atPoint: CGPoint(x: 0, y: pointY), scale: scale)
        
        return currentImage
    }
    
    convenience init(image: UIImage, text: String, color: UIColor, font: UIFont, scale: CGFloat) {
        self.init()
        self.image = image
        self.font = font
        self.text = text
        self.color = color
        self.scale = scale
        self.image = compositeImage ?? image
    }
}

extension CGSize {
    fileprivate static func +(lhs: CGSize, rhs: CGSize) -> CGSize {
        return CGSize(width: lhs.width + rhs.width, height: lhs.height +  rhs.height)
    }
}

extension Array where Element == VisualInstruction.Component {
    fileprivate func component(before component: VisualInstruction.Component) -> VisualInstruction.Component? {
        guard let index = self.firstIndex(of: component) else {
            return nil
        }
        if index > 0 {
            return self[index-1]
        }
        return nil
    }
    
    fileprivate func component(after component: VisualInstruction.Component) -> VisualInstruction.Component? {
        guard let index = self.firstIndex(of: component) else {
            return nil
        }
        if index+1 < self.endIndex {
            return self[index+1]
        }
        return nil
    }
}
