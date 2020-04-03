import MapboxDirections
import MapboxCoreNavigation

public typealias StepPath = (leg: Int, step: Int)



/// :nodoc:
open class InstructionsCardViewController: UIViewController {
    typealias InstructionsCardCollectionLayout = UICollectionViewFlowLayout
    
    public var routeProgress: RouteProgress?
    var cardSize: CGSize = .zero
    public var cardStyle: DayInstructionsCardStyle = DayInstructionsCardStyle()
    
    var instructionCollectionView: UICollectionView!
    var instructionsCardLayout: InstructionsCardCollectionLayout!
    
    public private(set) var isInPreview = false
    public var currentPath: StepPath?
    
    public var steps: [[RouteStep]]? {
        guard let progress = routeProgress else { return nil }
        
        
        let stepIndex = progress.currentLegProgress.stepIndex
        let remainingStepsOnCurrentLeg: [[RouteStep]] = [progress.currentLeg.steps.suffix(from: stepIndex).dropLast()]
        
        let remainingSteps: [[RouteStep]] = progress.remainingLegs.map {
            if $0 == progress.route.legs.last {
                return $0.steps
            } else {
                return $0.steps.dropLast()
            }
        }
        
        let answer: [[RouteStep]] = remainingStepsOnCurrentLeg + remainingSteps
        
        return answer
        }

    /**
     The InstructionsCardCollection delegate.
     */
    public weak var cardCollectionDelegate: InstructionsCardCollectionDelegate?
    
    fileprivate var contentOffsetBeforeSwipe = CGPoint(x: 0, y: 0)
    fileprivate var indexBeforeSwipe = IndexPath(row: 0, section: 0)
    fileprivate var isSnapAndRemove = false
    public let cardCollectionCellIdentifier = "InstructionsCardCollectionCellID"
    fileprivate let collectionViewFlowLayoutMinimumSpacingDefault: CGFloat = 10.0
    fileprivate let collectionViewPadding: CGFloat = 8.0
    
    lazy open var topPaddingView: TopBannerView =  {
        let view: TopBannerView = .forAutoLayout()
        return view
    }()
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        /* TODO: Identify the traitCollections to define the width of the cards */
        if let customSize = cardCollectionDelegate?.instructionsCardCollection(self, cardSizeFor: traitCollection) {
            cardSize = customSize
        } else {
            cardSize = CGSize(width: Int(floor(view.frame.size.width * 0.82)), height: 200)
        }
        
        /* TODO: Custom dataSource */
        
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        
        instructionsCardLayout = InstructionsCardCollectionLayout()
        instructionsCardLayout.scrollDirection = .horizontal
        instructionsCardLayout.itemSize = cardSize
        
        instructionCollectionView = UICollectionView(frame: .zero, collectionViewLayout: instructionsCardLayout)
        instructionCollectionView.register(InstructionsCardCell.self, forCellWithReuseIdentifier: cardCollectionCellIdentifier)
        instructionCollectionView.contentInset = UIEdgeInsets(top: 0, left: collectionViewPadding, bottom: 0, right: collectionViewPadding)
        instructionCollectionView.contentOffset = CGPoint(x: -collectionViewPadding, y: 0.0)
        instructionCollectionView.dataSource = self
        instructionCollectionView.delegate = self
        
        instructionCollectionView.showsVerticalScrollIndicator = false
        instructionCollectionView.showsHorizontalScrollIndicator = false
        instructionCollectionView.backgroundColor = .clear
        instructionCollectionView.isPagingEnabled = true
        instructionCollectionView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubviews()
        setConstraints()
        
        view.clipsToBounds = false
        topPaddingView.backgroundColor = .clear
    }
    
    func addSubviews() {
        [topPaddingView, instructionCollectionView].forEach(view.addSubview(_:))
    }
    
    func setConstraints() {
        let topPaddingConstraints: [NSLayoutConstraint] = [
            topPaddingView.topAnchor.constraint(equalTo: view.topAnchor),
            topPaddingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topPaddingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topPaddingView.bottomAnchor.constraint(equalTo: view.safeTopAnchor),
        ]
        
        NSLayoutConstraint.activate(topPaddingConstraints)
        
        let instructionCollectionViewContraints: [NSLayoutConstraint] = [
            instructionCollectionView.topAnchor.constraint(equalTo: topPaddingView.bottomAnchor),
            instructionCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            instructionCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            instructionCollectionView.heightAnchor.constraint(equalToConstant: cardSize.height),
            instructionCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ]
        
        NSLayoutConstraint.activate(instructionCollectionViewContraints)
    }
    
    open func reloadDataSource() {
        if currentPath == nil, let progress = routeProgress {
            currentPath = (leg: progress.legIndex, step: progress.currentLegProgress.stepIndex)
            instructionCollectionView.reloadData()
        } else if let progress = routeProgress, let (legIndex, stepIndex) = currentPath, legIndex != progress.legIndex, stepIndex != progress.currentLegProgress.stepIndex {
            currentPath = (leg: progress.legIndex, step: progress.currentLegProgress.stepIndex)
            instructionCollectionView.reloadData()
        } else {
            updateVisibleInstructionCards(at: instructionCollectionView.indexPathsForVisibleItems)
        }
    }
    
    open func updateVisibleInstructionCards(at indexPaths: [IndexPath]) {
        guard let progress = routeProgress else { return }
        let legProgress = progress.currentLegProgress
        let remainingSteps = legProgress.remainingSteps
        guard let currentCardStep = remainingSteps.first else { return }
        
        for (_, path) in indexPaths.enumerated() {
            if let steps = steps, let container = instructionContainerView(at: path), path.section < progress.route.legs.endIndex, path.row < remainingSteps.endIndex {
                let visibleStep = steps[path.section][path.row]
                let distance = currentCardStep == visibleStep ? legProgress.currentStepProgress.distanceRemaining : visibleStep.distance
                 container.updateInstructionCard(distance: distance)
             }
        }
    }
    
    func snapToIndexPath(_ indexPath: IndexPath) {
        guard let itemCount = steps?.count, itemCount >= 0 && indexPath.row < itemCount else { return }
        instructionsCardLayout.collectionView?.scrollToItem(at: indexPath, at: .left, animated: true)
    }
    
    public func stopPreview() {
        guard isInPreview else { return }
        instructionCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: false)
        isInPreview = false
    }
    
    public func instructionContainerView(at indexPath: IndexPath) -> InstructionsCardContainerView? {
        guard let cell = instructionCollectionView.cellForItem(at: indexPath),
            cell.subviews.count > 1 else {
                return nil
        }
        
        return cell.subviews[1] as? InstructionsCardContainerView
    }
    
    fileprivate func snappedIndexPath() -> IndexPath {
        guard let collectionView = instructionsCardLayout.collectionView, let legCount = steps?.count, let stepCount = steps?.map({ $0.count }) else {
            return IndexPath(row: 0, section: 0)
        }
        
        let estimatedIndex = Int(round((collectionView.contentOffset.x + collectionView.contentInset.left) / (cardSize.width + collectionViewFlowLayoutMinimumSpacingDefault)))
        let cellCount = estimatedIndex + 1
        
        var totalProcessedSteps = 0
        var stepIndex = 0
        var legIndex = 0
        var stop = false

        for legCount in stepCount {
            guard !stop else { break }
            if totalProcessedSteps + legCount >= cellCount {
                stop = true
                stepIndex = (cellCount - totalProcessedSteps) - 1
            } else {
                totalProcessedSteps += legCount
                legIndex += 1
            }
        }

    
        
        let boundedStepIndex = max(0, min(stepCount[legIndex] - 1, stepIndex))
        let boundedLegIndex = max(0, min(legCount - 1, legIndex))
        let path = IndexPath(row: boundedStepIndex, section: boundedLegIndex)
        print("Snapped Path: \(path), unbound (\(legIndex), \(stepIndex))")
        return path
    }
    
    fileprivate func scrollTargetIndexPath(for scrollView: UIScrollView, with velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) -> IndexPath {
        targetContentOffset.pointee = scrollView.contentOffset
        
        guard let steps = steps else { return IndexPath(row: 0, section: 0) }
        
        let legCount = steps.count
        let currentLegIndex = indexBeforeSwipe.section
        let itemCount = steps[currentLegIndex].count
        let velocityThreshold: CGFloat = 0.4
        
        let canSlideToNext = indexBeforeSwipe.row + 1 < itemCount || (currentLegIndex + 1 < legCount && !(steps[currentLegIndex + 1].isEmpty) )
        let hasVelocityToSlideToNext = canSlideToNext && velocity.x > velocityThreshold

        let willIncrementLegOnNext = indexBeforeSwipe.row + 1 == itemCount
        
        let canSlideToPrev = indexBeforeSwipe.row - 1 >= 0 || (currentLegIndex > 0 && !(steps[currentLegIndex - 1].isEmpty))
        let hasVelocityToSlidePrev = canSlideToPrev && velocity.x < -velocityThreshold
        let willDecrementLegOnPrev = indexBeforeSwipe.row == 0
        
        let didSwipe = hasVelocityToSlideToNext || hasVelocityToSlidePrev
        
        let scrollTargetIndexPath: IndexPath!
        
        if didSwipe {
            if hasVelocityToSlideToNext {
                let section = willIncrementLegOnNext ? currentLegIndex + 1 : currentLegIndex
                let row = willIncrementLegOnNext ? 0 : indexBeforeSwipe.row + 1
                scrollTargetIndexPath = IndexPath(row: row, section: section)
            } else {
                let section = willDecrementLegOnPrev ? currentLegIndex - 1 : currentLegIndex
                let row = willDecrementLegOnPrev ? steps[currentLegIndex - 1].count - 1 : indexBeforeSwipe.row - 1
                scrollTargetIndexPath = IndexPath(row: row, section: section)
            }
        } else {
            if scrollView.contentOffset.x - contentOffsetBeforeSwipe.x < -cardSize.width / 2 {
                let section = willDecrementLegOnPrev ? currentLegIndex - 1 : currentLegIndex
                let row = willDecrementLegOnPrev ? steps[currentLegIndex - 1].count - 1 : indexBeforeSwipe.row - 1
                scrollTargetIndexPath = IndexPath(row: row, section: section)
            } else if scrollView.contentOffset.x - contentOffsetBeforeSwipe.x > cardSize.width / 2 {
                 let section = willIncrementLegOnNext ? currentLegIndex + 1 : currentLegIndex
                 let row = willIncrementLegOnNext ? 0 : indexBeforeSwipe.row + 1
                 scrollTargetIndexPath = IndexPath(row: row, section: section)
            } else {
                scrollTargetIndexPath = indexBeforeSwipe
            }
        }
        
        return scrollTargetIndexPath
    }
}

/// :nodoc:
extension InstructionsCardViewController: UICollectionViewDelegate {
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        indexBeforeSwipe = snappedIndexPath()
        contentOffsetBeforeSwipe = scrollView.contentOffset
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let indexPath = scrollTargetIndexPath(for: scrollView, with: velocity, targetContentOffset: targetContentOffset)
        snapToIndexPath(indexPath)
        
        isInPreview = true
        let legIndex = indexPath.section
        let stepIndex = indexPath.row
        
        assert(legIndex >= 0 && stepIndex >= 0, "Indicies should not be negative")
        guard isInPreview, let steps = steps else { return }
        
        
        switch stepIndex {
        case 0 where legIndex > 0:
            let leg = steps[legIndex - 1]
            let step = leg[leg.endIndex - 1]
            
            cardCollectionDelegate?.instructionsCardCollection(self, didPreview: step)
        case steps[legIndex].endIndex - 1 where legIndex < steps.endIndex - 1:
            let leg = steps[legIndex + 1]
            let step = leg[0]
            
            cardCollectionDelegate?.instructionsCardCollection(self, didPreview: step)
        case 1..<(steps[legIndex].endIndex - 1):
            let step = steps[legIndex][stepIndex]
            cardCollectionDelegate?.instructionsCardCollection(self, didPreview: step)
        default:
            return
        }
    }
}

/// :nodoc:
extension InstructionsCardViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let steps = steps else {
            return 0
        }
        
        return steps[section].count
    }
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return steps?.count ?? 0
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cardCollectionCellIdentifier, for: indexPath) as! InstructionsCardCell
        
        guard let steps = steps, indexPath.section < steps.endIndex, indexPath.row < steps[indexPath.section].endIndex, let distanceRemaining = routeProgress?.currentLegProgress.currentStepProgress.distanceRemaining else {
            return cell
        }
        
        
        if indexPath.section > 0 {
            print("Next Section!")
        }
        
        cell.style = cardStyle
        cell.container.delegate = self
        
        let step = steps[indexPath.section][indexPath.row]
        let firstStep = indexPath.section == 0 && indexPath.row == 0
        let distance = firstStep ? distanceRemaining : step.distance
        cell.configure(for: step, distance: distance)
        
        return cell
    }
}

/// :nodoc:
extension InstructionsCardViewController: UICollectionViewDelegateFlowLayout {
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return cardSize
    }
}

/// :nodoc:
extension InstructionsCardViewController: NavigationComponent {
    public func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        routeProgress = progress
        reloadDataSource()
    }
    
    public func navigationService(_ service: NavigationService, didPassVisualInstructionPoint instruction: VisualInstructionBanner, routeProgress: RouteProgress) {
        self.routeProgress = routeProgress
        reloadDataSource()
    }
    
    public func navigationService(_ service: NavigationService, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool) {
        self.currentPath = nil
        self.routeProgress = service.routeProgress
        reloadDataSource()
    }
}

/// :nodoc:
extension InstructionsCardViewController: InstructionsCardContainerViewDelegate {
    public func primaryLabel(_ primaryLabel: InstructionLabel, willPresent instruction: VisualInstruction, as presented: NSAttributedString) -> NSAttributedString? {
        return cardCollectionDelegate?.primaryLabel(primaryLabel, willPresent: instruction, as: presented)
    }
    
    public func secondaryLabel(_ secondaryLabel: InstructionLabel, willPresent instruction: VisualInstruction, as presented: NSAttributedString) -> NSAttributedString? {
        return cardCollectionDelegate?.secondaryLabel(secondaryLabel, willPresent: instruction, as: presented)
    }
}

/// :nodoc:
extension InstructionsCardViewController: NavigationMapInteractionObserver {
    public func navigationViewController(didCenterOn location: CLLocation) {
        stopPreview()
    }
}
