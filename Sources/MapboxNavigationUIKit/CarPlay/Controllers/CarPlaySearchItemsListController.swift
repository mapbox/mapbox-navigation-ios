//
//  CarPlaySearchItemsListController.swift
//
//
//  Created by Maksim Chizhavko on 12/16/24.
//

import CarPlay
import Foundation

@_spi(MapboxInternal)
public protocol CarPlaySearchItemsListControllerDelegate: AnyObject {
    func didSelectBackButton(_ controller: CarPlaySearchItemsListController)
    func didSelectItem(
        _ controller: CarPlaySearchItemsListController,
        item: CarPlayListItem,
        handler: @escaping () -> Void
    )
}

@_spi(MapboxInternal)
public final class CarPlaySearchItemsListController {
    public struct Style {
        var title: String
        var backItemTitle: String
        var items: [CarPlayListItem]

        public init(title: String, backItemTitle: String = "Back", items: [CarPlayListItem]) {
            self.title = title
            self.backItemTitle = backItemTitle
            self.items = items
        }
    }

    public weak var delegate: CarPlaySearchItemsListControllerDelegate?
    public let template: CPListTemplate
    private let style: Style

    public init(style: Style) {
        self.style = style
        self.template = .init(title: style.title, sections: [])
        postInit()
    }

    private func postInit() {
        template.backButton = .init(title: style.backItemTitle) { [weak self] _ in
            guard let self else { return }
            delegate?.didSelectBackButton(self)
        }

        configureSections(using: style.items)
    }

    private func configureSections(using listItems: [CarPlayListItem]) {
        var newItems: [CPListItem] = []

        for item in listItems {
            let newItem = CPListItem(
                text: item.text,
                detailText: item.detailText,
                image: item.icon,
                accessoryImage: nil,
                accessoryType: .disclosureIndicator
            )

            newItem.handler = { [weak self, item] _, completion in
                guard let self else { return }
                delegate?.didSelectItem(self, item: item, handler: completion)
            }
            newItems.append(newItem)
        }

        template.updateSections([
            .init(items: newItems),
        ])
    }
}
