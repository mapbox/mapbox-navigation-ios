import UIKit
import MapboxCoreNavigation

class FeedbackSubtypeViewController: FeedbackViewController {

    public var activeFeedbackType: FeedbackType?

    private let reportButtonContainer = UIView()
    private let reportButtonSeparator = UIView()
    private let reportButton = UIButton()

    private var selectedItems = [FeedbackItem]()

    /**
     Initialize a new FeedbackSubtypeViewController from a `NavigationEventsManager`.
     */
    public init(eventsManager: NavigationEventsManager, feedbackType: FeedbackType) {
        super.init(eventsManager: eventsManager)
        self.activeFeedbackType = feedbackType
        reportButton.setBackgroundImage(UIImage(color: #colorLiteral(red: 0.337254902, green: 0.6588235294, blue: 0.9843137255, alpha: 1)), for: .normal)
        reportButton.layer.cornerRadius = 24
        reportButton.clipsToBounds = true
        reportButton.addTarget(self, action: #selector(reportButtonTapped(_:)), for: .touchUpInside)

        collectionView.register(FeedbackSubtypeCollectionViewCell.self, forCellWithReuseIdentifier: FeedbackSubtypeCollectionViewCell.defaultIdentifier)
        collectionView.allowsMultipleSelection = true

        reportIssueLabel.text = feedbackType.title

        updateButtonTitle()
    }

    @objc private func reportButtonTapped(_ sender: UIButton) {
        sendReport()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var sections: [FeedbackItem] {
        get {
            guard let activeFeedbackType = activeFeedbackType else { return [] }
            switch activeFeedbackType {
            case .general:
                return []
            case .incorrectVisual(_):
                return [FeedbackType.incorrectVisual(subtype: .turnIconIncorrect),
                        FeedbackType.incorrectVisual(subtype: .streetNameIncorrect),
                        FeedbackType.incorrectVisual(subtype: .instructionUnnecessary),
                        FeedbackType.incorrectVisual(subtype: .instructionMissing),
                        FeedbackType.incorrectVisual(subtype: .maneuverIncorrect),
                        FeedbackType.incorrectVisual(subtype: .exitInfoIncorrect),
                        FeedbackType.incorrectVisual(subtype: .laneGuidanceIncorrect),
                        FeedbackType.incorrectVisual(subtype: .roadKnownByDifferentName),
                        FeedbackType.incorrectVisual(subtype: .other)].map { $0.generateFeedbackItem() }
            case .confusingAudio(_):
                return [FeedbackType.confusingAudio(subtype: .guidanceTooEarly),
                        FeedbackType.confusingAudio(subtype: .guidanceTooLate),
                        FeedbackType.confusingAudio(subtype: .pronunciationIncorrect),
                        FeedbackType.confusingAudio(subtype: .roadNameRepeated),
                        FeedbackType.confusingAudio(subtype: .other)].map { $0.generateFeedbackItem() }
            case .routeQuality(_):
                return [FeedbackType.routeQuality(subtype: .routeNonDrivable),
                        FeedbackType.routeQuality(subtype: .routeNotPreferred),
                        FeedbackType.routeQuality(subtype: .alternativeRouteNotExpected),
                        FeedbackType.routeQuality(subtype: .routeIncludedMissingRoads),
                        FeedbackType.routeQuality(subtype: .other)].map { $0.generateFeedbackItem() }
            case .illegalRoute(_):
                return [FeedbackType.illegalRoute(subtype: .routedDownAOneWay),
                        FeedbackType.illegalRoute(subtype: .turnWasNotAllowed),
                        FeedbackType.illegalRoute(subtype: .carsNotAllowedOnStreet),
                        FeedbackType.illegalRoute(subtype: .turnAtIntersectionUnprotected),
                        FeedbackType.illegalRoute(subtype: .other)].map { $0.generateFeedbackItem() }
            case .roadClosure(_):
                return [FeedbackType.roadClosure(subtype: .streetPermanentlyBlockedOff),
                        FeedbackType.roadClosure(subtype: .roadMissingFromMap),
                        FeedbackType.roadClosure(subtype: .other)].map { $0.generateFeedbackItem() }
            case .positioning(_):
                return [FeedbackType.positioning(subtype: .userPosition)].map { $0.generateFeedbackItem() }
            }
        }
    }

    override var draggableHeight: CGFloat {
        return UIScreen.main.bounds.height - UIApplication.shared.statusBarFrame.size.height
    }

    public override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var availableWidth = collectionView.bounds.width
        
        if #available(iOS 11.0, *), let keyWindow = UIApplication.shared.keyWindow {
            availableWidth = keyWindow.safeAreaLayoutGuide.layoutFrame.size.width
        }
        
        return CGSize(width: availableWidth, height: 80)
    }

    public override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FeedbackSubtypeCollectionViewCell.defaultIdentifier, for: indexPath) as! FeedbackSubtypeCollectionViewCell
        let item = sections[indexPath.row]

        cell.titleLabel.text = item.title

        if indexPath.row == sections.count - 1 {
            cell.separatorColor = .clear
        } else {
            if #available(iOS 13.0, *) {
                cell.separatorColor = .separator
            } else {
                cell.separatorColor = UIColor(white: 0.95, alpha: 1.0)
            }
        }

        return cell
    }

    public override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        let cell = collectionView.cellForItem(at: indexPath) as! FeedbackSubtypeCollectionViewCell
        if #available(iOS 13.0, *) {
            cell.circleColor = .systemBlue
        } else {
            cell.circleColor = .lightGray
        }
        cell.circleOutlineColor = cell.circleColor

        let item = sections[indexPath.row]
        selectedItems.append(item)

        updateButtonTitle()
    }

    public func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! FeedbackSubtypeCollectionViewCell
        if #available(iOS 13.0, *) {
            cell.circleColor = .systemBackground
            cell.circleOutlineColor = .label
        } else {
            cell.circleColor = .white
            cell.circleOutlineColor = .darkText
        }

        let item = sections[indexPath.row]
        selectedItems.removeAll { existingItem -> Bool in
            return existingItem.feedbackType.title == item.feedbackType.title
        }

        updateButtonTitle()
    }

    private func updateButtonTitle() {
        if selectedItems.count == 0 {
            reportButton.setTitle(NSLocalizedString("NAVIGATION_REPORT_CANCEL", bundle: .mapboxNavigation, value: "Cancel", comment: "Title for button that cancels user's submission of feedback on navigation session issues."), for: .normal)
            
        } else {
            reportButton.setTitle(String.localizedStringWithFormat(NSLocalizedString("NAVIGATION_REPORT_ISSUES", bundle: .mapboxNavigation, value: "Send %ld Item(s)",  comment: "Title for button that submits user's feedback on multiple navigation session issues. 1 is the number of items"), selectedItems.count), for: .normal)
        }
    }

    private func sendReport() {
        if selectedItems.count > 0 {
            if let uuid = self.uuid {
                for item in selectedItems {
                    delegate?.feedbackViewController(self, didSend: item, uuid: uuid)
                    eventsManager?.updateFeedback(uuid: uuid, type: item.feedbackType, source: .user, description: nil)
                }
            }

            guard let parent = presentingViewController else {
                dismiss(animated: true)
                return
            }

            dismiss(animated: true) {
                DialogViewController().present(on: parent)
            }
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    internal override func setupViews() {
        super.setupViews()
        reportButtonContainer.translatesAutoresizingMaskIntoConstraints = false
        reportButton.translatesAutoresizingMaskIntoConstraints = false
        reportButtonContainer.addSubview(reportButton)
        reportButtonContainer.addSubview(reportButtonSeparator)
        reportButtonSeparator.translatesAutoresizingMaskIntoConstraints = false
        if #available(iOS 13.0, *) {
            reportButtonSeparator.backgroundColor = .separator
        } else {
            reportButtonSeparator.backgroundColor = .lightGray
        }
        view.addSubview(reportButtonContainer)
    }

    internal override func setupConstraints() {
        let labelTop = reportIssueLabel.topAnchor.constraint(equalTo: view.topAnchor)
        let labelHeight = reportIssueLabel.heightAnchor.constraint(equalToConstant: FeedbackViewController.titleHeaderHeight)
        let labelLeading = reportIssueLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let labelTrailing = reportIssueLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        let collectionLabelSpacing = collectionView.topAnchor.constraint(equalTo: reportIssueLabel.bottomAnchor)
        let collectionLeading = collectionView.leadingAnchor.constraint(equalTo: view.safeLeadingAnchor)
        let collectionTrailing = collectionView.trailingAnchor.constraint(equalTo: view.safeTrailingAnchor)
        let collectionBarSpacing = collectionView.bottomAnchor.constraint(equalTo: reportButtonContainer.topAnchor)

        let reportButtonContainerLeading = reportButtonContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        let reportButtonContainerTrailing = reportButtonContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        let reportButtonContainerBottom = reportButtonContainer.bottomAnchor.constraint(equalTo: view.safeBottomAnchor)
        let reportButtonContainerHeight = reportButtonContainer.heightAnchor.constraint(equalToConstant: 96)

        let reportButtonSeparatorLeading = reportButtonSeparator.leadingAnchor.constraint(equalTo: reportButtonContainer.leadingAnchor)
        let reportButtonSeparatorTrailing = reportButtonSeparator.trailingAnchor.constraint(equalTo: reportButtonContainer.trailingAnchor)
        let reportButtonSeparatorTop = reportButtonSeparator.bottomAnchor.constraint(equalTo: reportButtonContainer.topAnchor)
        let reportButtonSeparatorHeight = reportButtonSeparator.heightAnchor.constraint(equalToConstant: 0.5)

        let reportButtonCenterX = reportButton.centerXAnchor.constraint(equalTo: reportButtonContainer.centerXAnchor)
        let reportButtonCenterY = reportButton.centerYAnchor.constraint(equalTo: reportButtonContainer.centerYAnchor)
        let reportButtonWidth = reportButton.widthAnchor.constraint(equalToConstant: 165)
        let reportButtonHeight = reportButton.heightAnchor.constraint(equalToConstant: 48)

        let constraints = [
            labelTop,
            labelHeight,
            labelLeading,
            labelTrailing,
            collectionLabelSpacing,
            collectionLeading,
            collectionTrailing,
            collectionBarSpacing,
            reportButtonContainerLeading,
            reportButtonContainerTrailing,
            reportButtonContainerBottom,
            reportButtonContainerHeight,
            reportButtonCenterX,
            reportButtonCenterY,
            reportButtonWidth,
            reportButtonHeight,
            reportButtonSeparatorLeading,
            reportButtonSeparatorTrailing,
            reportButtonSeparatorTop,
            reportButtonSeparatorHeight
        ]

        NSLayoutConstraint.activate(constraints)
    }
}
