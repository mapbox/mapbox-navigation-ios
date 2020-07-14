import MapboxDirections
import MapboxCoreNavigation

/// :nodoc:
open class InstructionsCardViewController: UIViewController {
    typealias InstructionsCardCollectionLayout = UICollectionViewFlowLayout
    
    public var routeProgress: RouteProgress?
    var cardSize: CGSize = .zero
    public var cardStyle: DayInstructionsCardStyle = DayInstructionsCardStyle()
    
    var instructionCollectionView: UICollectionView!
    var instructionsCardLayout: InstructionsCardCollectionLayout!
    
    lazy var junctionView: JunctionView = {
        let view: JunctionView = .forAutoLayout()
        view.isHidden = true
        view.applyDefaultCornerRadiusShadow(cornerRadius: 4, shadowOpacity: 0.4)
        return view
    }()
    
    public private(set) var isInPreview = false
    public var currentStepIndex: Int?
    
    public var steps: [RouteStep]? {
        guard let stepIndex = routeProgress?.currentLegProgress.stepIndex, let steps = routeProgress?.currentLeg.steps else { return nil }
        var mutatedSteps = steps
        if mutatedSteps.count > 1 {
            mutatedSteps = Array(mutatedSteps.suffix(from: stepIndex))
            mutatedSteps.removeLast()
        }
        return mutatedSteps
    }
    
    var distancesFromCurrentLocationToManeuver: [CLLocationDistance]? {
        guard let progress = routeProgress, let steps = steps else { return nil }
        let distanceRemaining = progress.currentLegProgress.currentStepProgress.distanceRemaining
        let distanceBetweenSteps = [distanceRemaining] + progress.remainingSteps.map {$0.distance}
        guard let firstDistance = distanceBetweenSteps.first else { return nil }
        
        var distancesFromCurrentLocationToManeuver = [CLLocationDistance]()
        distancesFromCurrentLocationToManeuver.reserveCapacity(steps.count)
        
        var cumulativeDistance: CLLocationDistance = firstDistance > 5 ? firstDistance : 0
        distancesFromCurrentLocationToManeuver.append(cumulativeDistance)
        
        for index in 1..<distanceBetweenSteps.endIndex {
            let safeIndex = index < distanceBetweenSteps.endIndex ? index : distanceBetweenSteps.endIndex - 1
            let previousDistance = distanceBetweenSteps[safeIndex-1]
            let currentDistance = distanceBetweenSteps[safeIndex]
            let cardDistance = previousDistance + currentDistance
            cumulativeDistance += cardDistance > 5 ? cardDistance : 0
            distancesFromCurrentLocationToManeuver.append(cumulativeDistance)
        }
        
        return distancesFromCurrentLocationToManeuver
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
        [topPaddingView, instructionCollectionView, junctionView].forEach(view.addSubview(_:))
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
        
        let junctionViewConstraints: [NSLayoutConstraint] = [
            junctionView.topAnchor.constraint(equalTo: instructionCollectionView.bottomAnchor),
            junctionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            junctionView.widthAnchor.constraint(equalToConstant: cardSize.width),
            junctionView.heightAnchor.constraint(equalTo: junctionView.widthAnchor, multiplier: 0.6) // aspect ratio fit
        ]
        
        NSLayoutConstraint.activate(junctionViewConstraints)
    }
    
    open func reloadDataSource() {
        if currentStepIndex == nil, let progress = routeProgress {
            currentStepIndex = progress.currentLegProgress.stepIndex
            instructionCollectionView.reloadData()
        } else if let progress = routeProgress, let stepIndex = currentStepIndex, stepIndex != progress.currentLegProgress.stepIndex {
            currentStepIndex = progress.currentLegProgress.stepIndex
            instructionCollectionView.reloadData()
        } else {
            updateVisibleInstructionCards(at: instructionCollectionView.indexPathsForVisibleItems)
        }
    }
    
    open func updateVisibleInstructionCards(at indexPaths: [IndexPath]) {
        guard let legProgress = routeProgress?.currentLegProgress else { return }
        let remainingSteps = legProgress.remainingSteps
        guard let currentCardStep = remainingSteps.first else { return }
        
        for index in indexPaths.startIndex..<indexPaths.endIndex {
            let indexPath = indexPaths[index]
            if let container = instructionContainerView(at: indexPath), indexPath.row < remainingSteps.endIndex {
                let visibleStep = remainingSteps[indexPath.row]
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
    
    fileprivate func calculateNeededSpace(count: Int) -> CGSize {
        let cardSize = instructionsCardLayout.itemSize
        return CGSize(width: (cardSize.width + 10) * CGFloat(count), height: cardSize.height)
    }
    
    fileprivate func snappedIndexPath() -> IndexPath {
        guard let collectionView = instructionsCardLayout.collectionView, let itemCount = steps?.count else {
            return IndexPath(row: 0, section: 0)
        }
        
        let estimatedIndex = Int(round((collectionView.contentOffset.x + collectionView.contentInset.left) / (cardSize.width + collectionViewFlowLayoutMinimumSpacingDefault)))
        let indexInBounds = max(0, min(itemCount - 1, estimatedIndex))
        
        return IndexPath(row: indexInBounds, section: 0)
    }
    
    fileprivate func scrollTargetIndexPath(for scrollView: UIScrollView, with velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) -> IndexPath {
        targetContentOffset.pointee = scrollView.contentOffset
        
        let itemCount = steps?.count ?? 0
        let velocityThreshold: CGFloat = 0.4
        
        let hasVelocityToSlideToNext = indexBeforeSwipe.row + 1 < itemCount && velocity.x > velocityThreshold
        let hasVelocityToSlidePrev = indexBeforeSwipe.row - 1 >= 0 && velocity.x < -velocityThreshold
        let didSwipe = hasVelocityToSlideToNext || hasVelocityToSlidePrev
        
        let scrollTargetIndexPath: IndexPath!
        
        if didSwipe {
            if hasVelocityToSlideToNext {
                scrollTargetIndexPath = IndexPath(row: indexBeforeSwipe.row + 1, section: 0)
            } else {
                scrollTargetIndexPath = IndexPath(row: indexBeforeSwipe.row - 1, section: 0)
            }
        } else {
            if scrollView.contentOffset.x - contentOffsetBeforeSwipe.x < -cardSize.width / 2 {
                scrollTargetIndexPath = IndexPath(row: indexBeforeSwipe.row - 1, section: 0)
            } else if scrollView.contentOffset.x - contentOffsetBeforeSwipe.x > cardSize.width / 2 {
                scrollTargetIndexPath = IndexPath(row: indexBeforeSwipe.row + 1, section: 0)
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
        let previewIndex = indexPath.row
        
        assert(previewIndex >= 0, "Preview Index should not be negative")
        if isInPreview, let steps = steps, previewIndex >= 0, previewIndex < steps.endIndex {
            let step = steps[previewIndex]
            cardCollectionDelegate?.instructionsCardCollection(self, didPreview: step)
        }
    }
}

/// :nodoc:
extension InstructionsCardViewController: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return steps?.count ?? 0
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cardCollectionCellIdentifier, for: indexPath) as! InstructionsCardCell
        
        guard let steps = steps, indexPath.row < steps.endIndex, let distanceRemaining = routeProgress?.currentLegProgress.currentStepProgress.distanceRemaining else {
            return cell
        }
        
        cell.style = cardStyle
        cell.container.delegate = self
        
        let step = steps[indexPath.row]
        let firstStep = indexPath.row == 0
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
        junctionView.update(for: instruction, service: service)
        reloadDataSource()
    }
    
    public func navigationService(_ service: NavigationService, didRerouteAlong route: Route, at location: CLLocation?, proactive: Bool) {
        self.currentStepIndex = nil
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
