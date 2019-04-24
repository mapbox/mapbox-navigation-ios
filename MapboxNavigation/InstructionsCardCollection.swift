import MapboxDirections
import MapboxCoreNavigation

@objc public protocol InstructionsCardCollectionDelegate {
    /**
     Called when the user scrolls through a series of guidance card.
     - parameter instructionsCardCollection: <Uncompleted documentation>
     - parameter step: <Uncompleted documentation>
     */
    @objc(instructionsCardCollection:previewFor:)
    func instructionsCardCollection(_ instructionsCardCollection: InstructionsCardCollection, previewFor step: RouteStep)
    
    /// :nodoc: needs documentation
    @objc(instructionsCardCollection:cardSizeForTraitcollection:)
    optional func instructionsCardCollection(_ instructionsCardCollection: InstructionsCardCollection, cardSizeForTraitcollection: UITraitCollection) -> CGSize
}

open class InstructionsCardCollection: ContainerViewController, TapSensitive {
    typealias InstructionsCardCollectionLayout = UICollectionViewFlowLayout
    typealias InstructionsCardCell = UICollectionViewCell
    
    var cardSize = CGSize(width: 307.0, height: 100.0)
    
    var dayStyle = DayInstructionsCardStyle()
    
    var instructionCollectionView: UICollectionView!
    var instructionsCardLayout: InstructionsCardCollectionLayout!
    var isInPreview = false
    
    var route: Route? {
        didSet {
            steps = route?.steps
        }
    }
    
    var steps: [RouteStep]? {
        didSet {
            update(steps: steps ?? [])
        }
    }
    
    var routeProgress: RouteProgress? {
        didSet {
            updateDistances()
            updateDistancesOnCards()
        }
    }
    
    var distancesFromCurrentLocationToManeuver: [CLLocationDistance]?
    
    /// :nodoc: needs documentation
    public weak var cardCollectionDelegate: InstructionsCardCollectionDelegate?
    
    fileprivate var contentOffsetBeforeSwipe = CGPoint(x: 0, y: 0)
    fileprivate var indexBeforeSwipe = IndexPath(row: 0, section: 0)
    fileprivate var isSnapAndRemove = false
    
    lazy open var topPaddingView: TopBannerView =  {
        let view: TopBannerView = .forAutoLayout()
        view.accessibilityIdentifier = "topPaddingView"
        return view
    }()
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "topBannerRoot"
        cardSize = cardCollectionDelegate?.instructionsCardCollection?(self, cardSizeForTraitcollection: traitCollection) ?? CGSize(width: 307.0, height: 100.0) // TODO: calculated screen width percentage to detect width of the card size
        
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        
        instructionsCardLayout = InstructionsCardCollectionLayout()
        instructionsCardLayout.scrollDirection = .horizontal
        instructionsCardLayout.itemSize = cardSize
        
        instructionCollectionView = UICollectionView(frame: .zero, collectionViewLayout: instructionsCardLayout)
        instructionCollectionView.register(InstructionsCardCell.self, forCellWithReuseIdentifier: "cell")
        instructionCollectionView.contentInset = UIEdgeInsets(top: 0, left: 8.0, bottom: 0, right: 8.0)
        instructionCollectionView.contentOffset = CGPoint(x: -8.0, y: 0.0)
        instructionCollectionView.dataSource = self
        instructionCollectionView.delegate = self
        
        instructionCollectionView.showsVerticalScrollIndicator = false
        instructionCollectionView.showsHorizontalScrollIndicator = false
        instructionCollectionView.backgroundColor = .clear
        instructionCollectionView.isPagingEnabled = true
        
        addSubviews()
        setConstraints()
        
        view.clipsToBounds = false
        topPaddingView.backgroundColor = .clear
        
        instructionCollectionView.translatesAutoresizingMaskIntoConstraints = false
        instructionCollectionView.topAnchor.constraint(equalTo: topPaddingView.bottomAnchor).isActive = true
        instructionCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        instructionCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        instructionCollectionView.heightAnchor.constraint(equalToConstant: cardSize.height).isActive = true
        instructionCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        instructionCollectionView.isHidden = false
    }
    
    func addSubviews() {
        [topPaddingView, instructionCollectionView].forEach(view.addSubview(_:))
    }
    
    func setConstraints() {
        let constraints: [NSLayoutConstraint] = [
            topPaddingView.topAnchor.constraint(equalTo: view.topAnchor),
            topPaddingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topPaddingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topPaddingView.bottomAnchor.constraint(equalTo: view.safeTopAnchor),
            
            ]
        
        NSLayoutConstraint.activate(constraints)
    }
    
    public func navigationService(_ service: NavigationService, didUpdate progress: RouteProgress, with location: CLLocation, rawLocation: CLLocation) {
        route = progress.route
        routeProgress = progress
        
    }
    
    func update(steps: [RouteStep]) {
        instructionCollectionView.contentSize = calculateNeededSpace(count: steps.count)
        instructionCollectionView.reloadData()
    }
    
    func refresh() {
        guard let progress = routeProgress else { return }
        
        var remainingSteps = progress.remainingSteps
        _ = remainingSteps.popLast() // ignore last step
        
        steps = [progress.currentLegProgress.currentStep] + remainingSteps
    }
    
    func didTap(_ source: TappableContainer) {
        
    }
    
    fileprivate func updateDistances() {
        guard let progress = routeProgress else { return }
        
        let distanceRemaining = progress.currentLegProgress.currentStepProgress.distanceRemaining
        let distanceBetweenSteps = [distanceRemaining] + progress.remainingSteps.map {$0.distance}
        distancesFromCurrentLocationToManeuver = steps?.enumerated().map { (index, _) in
            let safeIndex = index < distanceBetweenSteps.endIndex ? index : distanceBetweenSteps.endIndex - 1
            let cardDistance = distanceBetweenSteps[0...safeIndex].reduce(0, +)
            return cardDistance > 5 ? cardDistance : 0
        }
    }
    
    fileprivate func updateDistancesOnCards() {
        _ = distancesFromCurrentLocationToManeuver?.enumerated().map { (index, distance) in
            if let card = instructionsCardView(at: IndexPath(row: index, section: 0)) {
                card.distanceFromCurrentLocation = distance
                card.isActive = distance < card.highlightDistance
            }
        }
    }
    
    func updateInstruction(for step: RouteStep) {
        guard let progress   = routeProgress,
            let activeCard = instructionsCardView(at: IndexPath(row: 0, section: 0)) else { return }
        
        if !progress.currentLegProgress.isCurrentStep(activeCard.step) {
            isSnapAndRemove = true
            snapToIndex(index: IndexPath(row: 1, section: 0))
        }
    }
    
    func snapToIndex(index: IndexPath) {
        let itemCount = collectionView(instructionCollectionView, numberOfItemsInSection: 0)
        guard itemCount >= 0 && index.row < itemCount else { return }
        instructionsCardLayout.collectionView?.scrollToItem(at: index, at: .left, animated: true)
    }
    
    func stopPreview() {
        isInPreview = false
        
        guard let steps = steps else { return }
        
        if steps.first != routeProgress?.currentLegProgress.currentStep {
            guard let currentStep = routeProgress?.currentLegProgress.currentStep else { return }
            guard let stepIndex = steps.index(of: currentStep) else { return }
            self.steps = Array(steps.suffix(from: stepIndex))
            instructionCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: false)
        } else {
            snapToIndex(index: IndexPath(row: 0, section: 0))
        }
    }
    
    fileprivate func instructionsCardView(at index: IndexPath) -> InstructionsCardView? {
        let cell = instructionCollectionView.cellForItem(at: index)
        
        if cell?.subviews.count == 0 {
            return nil
        }
        
        return cell?.subviews[0] as? InstructionsCardView
    }
    
    fileprivate func calculateNeededSpace(count: Int) -> CGSize {
        let cardSize = instructionsCardLayout.itemSize
        return CGSize(width: cardSize.width * CGFloat(count), height: cardSize.height)
    }
    
    fileprivate func calculateIndexToSnapTo() -> IndexPath {
        guard let collectionView = instructionsCardLayout.collectionView,
            let itemCount      = steps?.count else { return IndexPath(row: 0, section: 0) }
        
        let collectionViewFlowLayoutMinimumSpacingDefault: CGFloat = 10.0
        let estimatedIndex = Int(round((collectionView.contentOffset.x + collectionView.contentInset.left) / (cardSize.width + collectionViewFlowLayoutMinimumSpacingDefault)))
        let indexInBounds = max(0, min(itemCount - 1, estimatedIndex))
        
        return IndexPath(row: indexInBounds, section: 0)
    }
}

extension InstructionsCardCollection: UICollectionViewDelegate {
    public func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        if isSnapAndRemove {
            isSnapAndRemove = false
            
            if let steps = steps {
                var mutatedSteps = Array(steps)
                mutatedSteps.remove(at: 0)
                self.steps = mutatedSteps
                instructionCollectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: false)
            }
        }
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        indexBeforeSwipe = calculateIndexToSnapTo()
        contentOffsetBeforeSwipe = scrollView.contentOffset
    }
    
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        targetContentOffset.pointee = scrollView.contentOffset
        
        let itemCount = steps?.count ?? 0
        let velocityThreshold: CGFloat = 0.4
        
        let hasVelocityToSlideToNext = indexBeforeSwipe.row + 1 < itemCount && velocity.x > velocityThreshold
        let hasVelocityToSlidePrev = indexBeforeSwipe.row - 1 >= 0 && velocity.x < -velocityThreshold
        let didSwipe = hasVelocityToSlideToNext || hasVelocityToSlidePrev
        
        let previewIndex: Int!
        let indexToSnapToo: IndexPath!
        
        if didSwipe {
            
            if hasVelocityToSlideToNext {
                indexToSnapToo = IndexPath(row: indexBeforeSwipe.row + 1, section: 0)
            } else {
                indexToSnapToo = IndexPath(row: indexBeforeSwipe.row - 1, section: 0)
            }
            
            snapToIndex(index: indexToSnapToo)
            previewIndex = indexToSnapToo.row
        } else {
            if scrollView.contentOffset.x - contentOffsetBeforeSwipe.x < -cardSize.width / 2 {
                indexToSnapToo = IndexPath(row: indexBeforeSwipe.row - 1, section: 0)
            } else if scrollView.contentOffset.x - contentOffsetBeforeSwipe.x > cardSize.width / 2 {
                indexToSnapToo = IndexPath(row: indexBeforeSwipe.row + 1, section: 0)
            } else {
                indexToSnapToo = indexBeforeSwipe
            }
            snapToIndex(index: indexToSnapToo)
            previewIndex = indexToSnapToo.row
        }
        
        isInPreview = previewIndex != indexBeforeSwipe.row
        
        if isInPreview, let previewStep = steps?[previewIndex] {
            cardCollectionDelegate?.instructionsCardCollection(self, previewFor: previewStep)
        }
    }
}

extension InstructionsCardCollection: UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return steps?.count ?? 0
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        guard let step = steps?[indexPath.row], let distance = distancesFromCurrentLocationToManeuver?[indexPath.row] else { return cell }
        
        if cell.subviews.count > 0 {
            for card in cell.subviews {
                card.removeFromSuperview()
            }
        }
        
        cell.backgroundColor = .clear
        cell.layer.shadowColor = UIColor.black.cgColor
        cell.layer.shadowOffset = CGSize(width: 1, height: 2)
        cell.layer.shadowRadius = 1
        cell.layer.shadowOpacity = 0.4
        
        let instructionsCard = InstructionsCardView()
        instructionsCard.step = step
        instructionsCard.distanceFromCurrentLocation = distance
        
        if let routeProgress = routeProgress,
            routeProgress.currentLegProgress.isCurrentStep(step) {
            let distanceRemaining = routeProgress.currentLegProgress.currentStepProgress.distanceRemaining
            let distance = distanceRemaining > 5 ? distanceRemaining : 0
            instructionsCard.isActive = distance < instructionsCard.highlightDistance
        }
        
        instructionsCard.accessibilityIdentifier = "InstructionsCard"
        cell.accessibilityIdentifier = "InstructionsCardCollectionCell"
        cell.addSubview(instructionsCard)
        
        // this helps us show a shadow
        instructionsCard.translatesAutoresizingMaskIntoConstraints = false
        instructionsCard.topAnchor.constraint(equalTo: cell.topAnchor, constant: 2).isActive = true
        instructionsCard.leadingAnchor.constraint(equalTo: cell.leadingAnchor).isActive = true
        instructionsCard.bottomAnchor.constraint(equalTo: cell.bottomAnchor, constant: -2).isActive = true
        instructionsCard.trailingAnchor.constraint(equalTo: cell.trailingAnchor).isActive = true
        
        return cell
    }
}

extension RouteProgress {
    var steps: [RouteStep] {
        var steps = [RouteStep]()
        
        let curStepIndex = currentLeg.steps.index(of: currentLegProgress.currentStep)
        for (index, step) in currentLeg.steps.enumerated() {
            if index < curStepIndex! {
                continue
            }
            
            if index == currentLeg.steps.count - 1 {
                continue
            }
            
            steps.append(step)
        }
        
        for leg in remainingLegs {
            var legSteps = leg.steps
            _ = legSteps.popLast()
            steps.append(contentsOf: legSteps)
        }
        
        return steps
    }
}

extension Route {
    var steps: [RouteStep] {
        var steps = [RouteStep]()
        
        for leg in legs {
            var legSteps = leg.steps
            _ = legSteps.popLast()
            steps.append(contentsOf: legSteps)
        }
        
        return steps
    }
}
