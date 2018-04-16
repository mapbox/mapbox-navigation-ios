import UIKit
import MapboxDirections

protocol InstructionPresenterDataSource: class {
    var availableBounds: (() -> CGRect)! { get }
    var font: UIFont! { get }
    var textColor: UIColor! { get }
    var shieldHeight: CGFloat { get }
}

protocol InstructionPresenterImageSource: class {
    func cachedImageForKey(_ key: String) -> UIImage?
    func imageWithURL(_ imageURL: URL, cacheKey: String, completion: @escaping (UIImage?) -> Void)
}

extension ImageRepository: InstructionPresenterImageSource {}

class InstructionPresenter {
    typealias DataSource = InstructionPresenterDataSource
    typealias ImageSource = InstructionPresenterImageSource
    private let instruction: [VisualInstructionComponent]

    required init(_ instruction: [VisualInstructionComponent], dataSource: DataSource, imageSource: ImageSource = ImageRepository.shared) {
        self.imageSource = imageSource
        self.instruction = instruction
        self.dataSource = dataSource
    }

    typealias ImageDownloadCompletion = (UIImage?) -> Void
    typealias ShieldDownloadCompletion = (NSAttributedString) -> ()
    
    var onShieldDownload: ShieldDownloadCompletion?

    private weak var dataSource: DataSource?
    private let imageSource: ImageSource
    
    func attributedText() -> NSAttributedString {
        let string = NSMutableAttributedString()
        fittedAttributedComponents().forEach { string.append($0) }
        return string
    }
    
    func fittedAttributedComponents() -> [NSAttributedString] {
        guard let source = self.dataSource else { return [] }
        var attributedPairs = self.attributedPairs(for: instruction, dataSource: source, imageSource: imageSource, onImageDownload: completeShieldDownload)
        let availableBounds = source.availableBounds()
        let totalWidth = attributedPairs.attributedStrings.map { $0.size() }.reduce(.zero, +).width
        let stringFits = totalWidth <= availableBounds.width
        
        guard !stringFits else { return attributedPairs.attributedStrings }
        
        let indexedComponents = attributedPairs.components.enumerated().map { IndexedVisualInstructionComponent(component: $1, index: $0) }
        let filtered = indexedComponents.filter { $0.component.abbreviation != nil }
        let sorted = filtered.sorted { $0.component.abbreviationPriority < $1.component.abbreviationPriority }
        for component in sorted {
            let isFirst = component.index == 0
            let joinChar = isFirst ? "" : " "
            guard component.component.type == .text else { continue }
            guard let abbreviation = component.component.abbreviation else { continue }
            
            attributedPairs.attributedStrings[component.index] = NSAttributedString(string: joinChar + abbreviation, attributes: attributes(for: source))
            let newWidth = attributedPairs.attributedStrings.map { $0.size() }.reduce(.zero, +).width
            
            if newWidth <= availableBounds.width {
                break
            }
        }
        
        return attributedPairs.attributedStrings
    }
    
    typealias AttributedInstructionComponents = (components: [VisualInstructionComponent], attributedStrings: [NSAttributedString])
    
    func attributedPairs(for components: [VisualInstructionComponent], dataSource: DataSource, imageSource: ImageSource, onImageDownload: ImageDownloadCompletion?) -> AttributedInstructionComponents {
        var strings: [NSAttributedString] = []
        var processedComponents: [VisualInstructionComponent] = []
        
        let exitInstructionIndex = components.index(where: {$0.type == .exit}) ?? NSNotFound
        let isExitInstruction = 0...1 ~= exitInstructionIndex
        
        for (index, component) in components.enumerated() {
            let isFirst = index == 0
            let joinChar = isFirst ? "" : " "
            let joinString = NSAttributedString(string: joinChar, attributes: attributes(for: dataSource))
            let initial = NSAttributedString()
            
            //This is the closure that builds the string.
            let build: (_: VisualInstructionComponent, _: [NSAttributedString]) -> Void = { (component, attributedStrings) in
                processedComponents.append(component)
                strings.append(attributedStrings.reduce(initial, +))
            }
            
            //Throw away exit components. We know this is safe because we know that if there is an exit component,
            //  there is an exit code component, and the latter contains the information we care about.

            guard component.type != .exit else { continue }
            
            //If we have a exit, in the first two components, lets handle that first.
            if component.maneuverType == .takeOffRamp,
                isExitInstruction, 0...1 ~= index,
                let exitString = attributedString(forExitComponent: component, dataSource: dataSource) {
        
                build(component, [exitString])
            }
                
            //If we have a shield, lets include those
            else if let shieldString = attributedString(forShieldComponent: component, imageSource: imageSource, dataSource: dataSource, onImageDownload: onImageDownload) {
                build(component, [joinString, shieldString])
            }
            
            else {
                //if it's a delimiter, skip it if it's between two shields. Otherwise, process the regular text component.
                if component.type == .delimiter {
                    
                    let componentBefore = components.component(before: component)
                    let componentAfter = components.component(after: component)
                    
                    if let shieldKey = componentBefore?.shieldKey(),
                        imageSource.cachedImageForKey(shieldKey) != nil {
                        continue
                    }
                    if let shieldKey = componentAfter?.shieldKey(),
                        imageSource.cachedImageForKey(shieldKey) != nil {
                        continue
                    }
                }
                guard let componentString = attributedString(forTextComponent: component, dataSource: dataSource) else { continue }
                build(component, [joinString, componentString])
            }
        }
        
        assert(processedComponents.count == strings.count, "The number of processed components must match the number of attributed strings")
        return (components: processedComponents, attributedStrings: strings)
    }

    func attributedString(forExitComponent exit: VisualInstructionComponent, dataSource: DataSource) -> NSAttributedString? {
        guard exit.type == .exitCode, let exitCode = exit.text else { return nil }
        let exitSide: ExitSide = exit.maneuverDirection == .left ? .left : .right
        guard let exitString = exitShield(side: exitSide, text: exitCode, dataSource: dataSource) else { return nil }
        return exitString
    }
    
    func attributedString(forShieldComponent shield: VisualInstructionComponent, imageSource:ImageSource, dataSource: DataSource, onImageDownload: ImageDownloadCompletion?) -> NSAttributedString? {
        guard let shieldKey = shield.shieldKey() else { return nil }
        
        //If we have the shield already cached, use that.
        if let cachedImage = imageSource.cachedImageForKey(shieldKey) {
            return attributedString(withFont: dataSource.font, shieldImage: cachedImage)
        }
        
        // Let's download the shield
        shieldImageForComponent(shield, in: imageSource, height: dataSource.shieldHeight, completion: onImageDownload)
        
        //and return the shield's code for usage in the meantime until download is complete.
        return attributedString(forTextComponent: shield, dataSource: dataSource)
    }
    
    func attributedString(forTextComponent component: VisualInstructionComponent, dataSource: DataSource) -> NSAttributedString? {
        guard let text = component.text else { return nil }
        return NSAttributedString(string: text, attributes: attributes(for: dataSource))
    }
    
    private func shieldImageForComponent(_ component: VisualInstructionComponent, in imageSource: ImageSource, height: CGFloat, completion: ImageDownloadCompletion?) {
        guard let imageURL = component.imageURL, let shieldKey = component.shieldKey() else {
            return
        }

        imageSource.imageWithURL(imageURL, cacheKey: shieldKey, completion: completion ?? {_ in } )
    }

    private func instructionHasDownloadedAllShields() -> Bool {
        for component in instruction {
            guard let key = component.shieldKey() else {
                continue
            }

            if imageSource.cachedImageForKey(key) == nil {
                return false
            }
        }
        return true
    }

    private func attributes(for dataSource: InstructionPresenterDataSource) -> [NSAttributedStringKey: Any] {
        return [.font: dataSource.font, .foregroundColor: dataSource.textColor]
    }

    private func attributedString(withFont font: UIFont, shieldImage: UIImage) -> NSAttributedString {
        let attachment = ShieldAttachment()
        attachment.font = font
        attachment.image = shieldImage
        return NSAttributedString(attachment: attachment)
    }
    
    private func exitShield(side: ExitSide = .right, text: String, dataSource: DataSource) -> NSAttributedString? {
        let exit = ExitView(pointSize: dataSource.font.pointSize, side: side, text: text)
        exit.translatesAutoresizingMaskIntoConstraints = false
        exit.invalidateIntrinsicContentSize()
        exit.setNeedsLayout()
        exit.layoutIfNeeded()
        let exitAttachment = ExitAttachment()
        guard let exitImage = takeSnapshot(on: exit) else { return nil }
        exitAttachment.image = exitImage
        exitAttachment.font = dataSource.font
        
        let exitString = NSAttributedString(attachment: exitAttachment)
        return exitString
    }
    
    private func completeShieldDownload(_ image: UIImage?) {
        onShieldDownload?(attributedText())
    }
    
    private func takeSnapshot(on view: UIView) -> UIImage?{
        let window = UIApplication.shared.delegate!.window!!
        
        window.addSubview(view)
        let image = view.imageRepresentation
        view.removeFromSuperview()
        return image
    }

}

protocol ImagePresenter {
    var image: UIImage? { get }
    var font: UIFont { get }
}

class ImageInstruction: NSTextAttachment, ImagePresenter {
    var font: UIFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
    
    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        guard let image = image else {
            return super.attachmentBounds(for: textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)
        }
        let yOrigin = (font.capHeight - image.size.height).rounded() / 2
        return CGRect(x: 0, y: yOrigin, width: image.size.width, height: image.size.height)
    }

}

class ShieldAttachment: ImageInstruction {}
class ExitAttachment: ImageInstruction {}

extension CGSize {
    fileprivate static var greatestFiniteSize = CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
    
    fileprivate static func +(lhs: CGSize, rhs: CGSize) -> CGSize {
        return CGSize(width: lhs.width + rhs.width, height: lhs.height +  rhs.height)
    }
}

fileprivate struct IndexedVisualInstructionComponent {
    let component: Array<VisualInstructionComponent>.Element
    let index: Array<VisualInstructionComponent>.Index
}

extension Array where Element == VisualInstructionComponent {
    fileprivate func component(before component: VisualInstructionComponent) -> VisualInstructionComponent? {
        guard let index = self.index(of: component) else {
            return nil
        }
        if index > 0 {
            return self[index-1]
        }
        return nil
    }
    
    fileprivate func component(after component: VisualInstructionComponent) -> VisualInstructionComponent? {
        guard let index = self.index(of: component) else {
            return nil
        }
        if index+1 < self.endIndex {
            return self[index+1]
        }
        return nil
    }
}
