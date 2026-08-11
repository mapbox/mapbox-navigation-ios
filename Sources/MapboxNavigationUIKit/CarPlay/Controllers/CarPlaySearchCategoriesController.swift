//
//  CarPlaySearchCategoriesController.swift
//
//
//  Created by Maksim Chizhavko on 12/16/24.
//

import CarPlay
import Combine
import MapboxDirections
import MapboxNavigationCore

@_spi(MapboxInternal)
public protocol CarPlaySearchCategoriesControllerDelegate: AnyObject, UnimplementedLogging {
    func didSelectBackButton(_ controller: CarPlaySearchCategoriesController)
    func didSelectKeyboardInput(_ controller: CarPlaySearchCategoriesController)
    func didSelectVoiceInput(_ controller: CarPlaySearchCategoriesController)
    func didSelectCategory(_ controller: CarPlaySearchCategoriesController, category: CarPlaySearchControllerCategory)
}

@_spi(MapboxInternal)
public final class CarPlaySearchCategoriesController {
    public struct Style {
        var title: String
        var backItemTitle: String
        var searchCategories: [CarPlaySearchControllerCategory]

        public init(
            title: String,
            backItemTitle: String = "Back",
            searchCategories: [CarPlaySearchControllerCategory]
        ) {
            self.title = title
            self.backItemTitle = backItemTitle
            self.searchCategories = searchCategories
        }
    }

    public var template: CPGridTemplate
    public weak var delegate: CarPlaySearchCategoriesControllerDelegate?

    private var lifetimeSubscriptions: Set<AnyCancellable> = []
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
            gridButtons: makeGridButtons(for: style.searchCategories)
        )

        template.backButton = .init(title: style.backItemTitle) { [weak self] _ in
            guard let self else { return }
            delegate?.didSelectBackButton(self)
        }

        let keyboardButton = CPBarButton(image: UIImage(systemName: "keyboard")!) { [weak self] _ in
            guard let self else { return }
            delegate?.didSelectKeyboardInput(self)
        }

        let voiceInputButton = CPBarButton(image: UIImage(systemName: "mic.fill")!) { [weak self] _ in
            guard let self else { return }
            delegate?.didSelectVoiceInput(self)
        }

        template.trailingNavigationBarButtons = [keyboardButton, voiceInputButton]
    }

    private func makeGridButtons(for searchCategories: [CarPlaySearchControllerCategory]) -> [CPGridButton] {
        var buttons: [CPGridButton] = []

        for category in searchCategories {
            buttons.append(.init(
                titleVariants: [category.displayName],
                image: category.icon,
                handler: { [weak self] _ in
                    guard let self else { return }
                    delegate?.didSelectCategory(self, category: category)
                }
            ))
        }
        return buttons
    }
}
