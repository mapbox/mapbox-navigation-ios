//
//  CarPlayGridController.swift
//
//
//  Created by Maksim Chizhavko on 1/24/25.
//

import CarPlay
import Foundation
import MapboxNavigationCore

@_spi(MapboxInternal)
public protocol CarPlayGridItem {
    var icon: UIImage { get }
    var displayName: String { get }
}

@_spi(MapboxInternal)
public enum CarPlayNavigationItem {
    case image(UIImage)
    case text(String)
}

@_spi(MapboxInternal)
public protocol CarPlayGridControllerDelegate: AnyObject, UnimplementedLogging {
    func didSelectBackButton(_ controller: CarPlayGridController)
    func didSelectNavigationItem(_ controller: CarPlayGridController, item: CarPlayNavigationItem, button: CPBarButton)
    func didSelectItem(_ controller: CarPlayGridController, item: CarPlayGridItem, button: CPGridButton)
}

@_spi(MapboxInternal)
extension CarPlayGridControllerDelegate {
    public func didSelectBackButton(_ controller: CarPlayGridController) {
        logUnimplemented(protocolType: CarPlayGridControllerDelegate.self, level: .info)
    }

    public func didSelectNavigationItem(
        _ controller: CarPlayGridController,
        item: CarPlayNavigationItem,
        button: CPBarButton
    ) {
        logUnimplemented(protocolType: CarPlayGridControllerDelegate.self, level: .info)
    }

    public func didSelectItem(_ controller: CarPlayGridController, item: CarPlayGridItem, button: CPGridButton) {
        logUnimplemented(protocolType: CarPlayGridControllerDelegate.self, level: .info)
    }
}

@_spi(MapboxInternal)
open class CarPlayGridController {
    public struct Style {
        var title: String
        var backItemTitle: String?
        var leadingNavigationItems: [CarPlayNavigationItem]
        var trailingNavigationItems: [CarPlayNavigationItem]
        var items: [CarPlayGridItem]

        public init(
            title: String,
            backItemTitle: String? = nil,
            items: [CarPlayGridItem],
            leadingNavigationItems: [CarPlayNavigationItem],
            trailingNavigationItems: [CarPlayNavigationItem]
        ) {
            self.title = title
            self.backItemTitle = backItemTitle
            self.items = items
            self.leadingNavigationItems = leadingNavigationItems
            self.trailingNavigationItems = trailingNavigationItems
        }
    }

    public var template: CPGridTemplate
    public weak var delegate: CarPlayGridControllerDelegate?

    private let style: Style

    public init(
        style: Style
    ) {
        // NOTE: Grid buttons need to capture `self` which isn't available here and old iOS versions doesn't support
        //       gridButtons updates, so to keep template non-optional we assign dummy template here and then create
        //       a proper one in `postInit`.
        self.template = .init(title: nil, gridButtons: [])
        self.style = style

        postInit()
    }

    private func postInit() {
        template = .init(
            title: style.title,
            gridButtons: makeGridButtons(for: style.items)
        )

        if let title = style.backItemTitle {
            template.backButton = .init(title: title) { [weak self] _ in
                guard let self else { return }
                delegate?.didSelectBackButton(self)
            }
        }

        template.leadingNavigationBarButtons = buildNavigationButtons(with: style.leadingNavigationItems)
        template.trailingNavigationBarButtons = buildNavigationButtons(with: style.trailingNavigationItems)
    }

    private func makeGridButtons(for items: [CarPlayGridItem]) -> [CPGridButton] {
        var buttons: [CPGridButton] = []

        for item in items {
            buttons.append(.init(
                titleVariants: [item.displayName],
                image: item.icon,
                handler: { [weak self] button in
                    guard let self else { return }
                    delegate?.didSelectItem(self, item: item, button: button)
                }
            ))
        }
        return buttons
    }

    private func buildNavigationButtons(with items: [CarPlayNavigationItem]) -> [CPBarButton] {
        items.map { item in
            switch item {
            case .image(let image):
                CPBarButton(image: image) { [weak self] button in
                    guard let self else { return }
                    delegate?.didSelectNavigationItem(self, item: item, button: button)
                }
            case .text(let text):
                CPBarButton(title: text) { [weak self] button in
                    guard let self else { return }
                    delegate?.didSelectNavigationItem(self, item: item, button: button)
                }
            }
        }
    }
}
