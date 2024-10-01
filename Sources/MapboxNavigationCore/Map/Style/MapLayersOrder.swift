import _MapboxNavigationHelpers
import MapboxMaps

/// Allows to order layers with easy by defining order rules and then query order for any added layer.
struct MapLayersOrder {
    @resultBuilder
    enum Builder {
        static func buildPartialBlock(first rule: Rule) -> [Rule] {
            [rule]
        }

        static func buildPartialBlock(first slottedRules: SlottedRules) -> [Rule] {
            slottedRules.rules
        }

        static func buildPartialBlock(accumulated rules: [Rule], next rule: Rule) -> [Rule] {
            with(rules) {
                $0.append(rule)
            }
        }

        static func buildPartialBlock(accumulated rules: [Rule], next slottedRules: SlottedRules) -> [Rule] {
            rules + slottedRules.rules
        }
    }

    struct SlottedRules {
        let rules: [MapLayersOrder.Rule]

        init(_ slot: Slot?, @MapLayersOrder.Builder rules: () -> [Rule]) {
            self.rules = rules().map { rule in
                with(rule) { $0.slot = slot }
            }
        }
    }

    struct Rule {
        struct MatchPredicate {
            let block: (String) -> Bool

            static func hasPrefix(_ prefix: String) -> Self {
                .init {
                    $0.hasPrefix(prefix)
                }
            }

            static func contains(_ substring: String) -> Self {
                .init {
                    $0.contains(substring)
                }
            }

            static func exact(_ id: String) -> Self {
                .init {
                    $0 == id
                }
            }

            static func any(of ids: any Sequence<String>) -> Self {
                let set = Set(ids)
                return .init {
                    set.contains($0)
                }
            }
        }

        struct OrderedAscendingComparator {
            let block: (_ lhs: String, _ rhs: String) -> Bool

            static func constant(_ value: Bool) -> Self {
                .init { _, _ in
                    value
                }
            }

            static func order(_ ids: [String]) -> Self {
                return .init { lhs, rhs in
                    guard let lhsIndex = ids.firstIndex(of: lhs),
                          let rhsIndex = ids.firstIndex(of: rhs) else { return true }
                    return lhsIndex < rhsIndex
                }
            }
        }

        let matches: (String) -> Bool
        let isOrderedAscending: (_ lhs: String, _ rhs: String) -> Bool
        var slot: Slot?

        init(
            predicate: MatchPredicate,
            isOrderedAscending: OrderedAscendingComparator
        ) {
            self.matches = predicate.block
            self.isOrderedAscending = isOrderedAscending.block
        }

        static func hasPrefix(
            _ prefix: String,
            isOrderedAscending: OrderedAscendingComparator = .constant(true)
        ) -> Rule {
            Rule(predicate: .hasPrefix(prefix), isOrderedAscending: isOrderedAscending)
        }

        static func contains(
            _ substring: String,
            isOrderedAscending: OrderedAscendingComparator = .constant(true)
        ) -> Rule {
            Rule(predicate: .contains(substring), isOrderedAscending: isOrderedAscending)
        }

        static func exact(
            _ id: String,
            isOrderedAscending: OrderedAscendingComparator = .constant(true)
        ) -> Rule {
            Rule(predicate: .exact(id), isOrderedAscending: isOrderedAscending)
        }

        static func orderedIds(_ ids: [String]) -> Rule {
            return Rule(
                predicate: .any(of: ids),
                isOrderedAscending: .order(ids)
            )
        }

        func slotted(_ slot: Slot) -> Self {
            with(self) {
                $0.slot = slot
            }
        }
    }

    /// Ids that are managed by map style.
    private var styleIds: [String] = []
    /// Ids that are managed by SDK.
    private var customIds: Set<String> = []
    /// Merged `styleIds` and `customIds` in order defined by rules.
    private var orderedIds: [String] = []
    /// A map from id to position in `orderedIds` to speed up `position(forId:)` query.
    private var orderedIdsIndices: [String: Int] = [:]
    private var idToSlot: [String: Slot] = [:]
    /// Ordered list of rules that define order.
    private let rules: [Rule]

    /// Used for styles with no slots support.
    private let legacyPosition: ((String) -> MapboxMaps.LayerPosition?)?

    init(
        @MapLayersOrder.Builder builder: () -> [Rule],
        legacyPosition: ((String) -> MapboxMaps.LayerPosition?)?
    ) {
        self.rules = builder()
        self.legacyPosition = legacyPosition
    }

    /// Inserts a new id and makes it possible to use it in `position(forId:)` method.
    mutating func insert(id: String) {
        customIds.insert(id)

        guard let ruleIndex = rules.firstIndex(where: { $0.matches(id) }) else {
            orderedIds.append(id)
            orderedIdsIndices[id] = orderedIds.count - 1
            return
        }

        func binarySearch() -> Int {
            var left = 0
            var right = orderedIds.count

            while left < right {
                let mid = left + (right - left) / 2
                if let currentRuleIndex = rules.firstIndex(where: { $0.matches(orderedIds[mid]) }) {
                    if currentRuleIndex > ruleIndex {
                        right = mid
                    } else if currentRuleIndex == ruleIndex {
                        if !rules[ruleIndex].isOrderedAscending(orderedIds[mid], id) {
                            right = mid
                        } else {
                            left = mid + 1
                        }
                    } else {
                        left = mid + 1
                    }
                } else {
                    right = mid
                }
            }
            return left
        }

        let insertionIndex = binarySearch()
        orderedIds.insert(id, at: insertionIndex)

        // Update the indices of the elements after the insertion point
        for index in insertionIndex..<orderedIds.count {
            orderedIdsIndices[orderedIds[index]] = index
        }

        idToSlot[id] = rule(matching: id)?.slot
    }

    /// Removes id from order.
    mutating func remove(id: String) {
        guard let index = orderedIdsIndices[id] else { return }

        orderedIds.remove(at: index)

        orderedIdsIndices.removeValue(forKey: id)
        for i in index..<orderedIds.count {
            orderedIdsIndices[orderedIds[i]] = i
        }
        idToSlot[id] = nil

        customIds.remove(id)
    }

    /// Sets style ids managed by the maps style.
    mutating func setStyleIds(_ ids: [String]) {
        styleIds = ids
        orderedIds = ids.filter { id in
            rules.contains(where: { $0.matches(id) })
        }

        // Reset the orderedIdsIndices dictionary and populate it with the initial orderedIds
        orderedIdsIndices = [:]
        for (index, id) in orderedIds.enumerated() {
            orderedIdsIndices[id] = index
        }

        customIds.forEach { insert(id: $0) }
    }

    /// Query the position for given layer id.
    func position(forId id: String) -> LayerPosition? {
        if let legacyPosition {
            return legacyPosition(id)
        }

        guard let index = orderedIdsIndices[id] else { return nil }
        let belowId = index == 0 ? nil : orderedIds[index - 1]
        let aboveId = index == orderedIds.count - 1 ? nil : orderedIds[index + 1]

        if let belowId {
            return .above(belowId)
        } else if let aboveId {
            return .below(aboveId)
        } else {
            return nil
        }
    }

    func slot(forId id: String) -> Slot? {
        idToSlot[id]
    }

    private func rule(matching id: String) -> Rule? {
        rules.first { rule in
            rule.matches(id)
        }
    }
}
