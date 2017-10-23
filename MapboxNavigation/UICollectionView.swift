import UIKit

extension UICollectionView {
    
    var numberOfRows: Int {
        let layout = (collectionViewLayout as? UICollectionViewFlowLayout)!
        
        var totalNumberOfItems = 0
        for section in 0...numberOfSections-1 {
            totalNumberOfItems += numberOfItems(inSection: section)
        }
        
        let insets = layout.sectionInset
        let width = bounds.width - insets.left - insets.right
        let cellWidth = layout.itemSize.width
        let cellSpacing = layout.minimumInteritemSpacing
        let numberOfItemsInRow = floor(width / (cellWidth + cellSpacing))
        let numberOfRows = ceil(CGFloat(totalNumberOfItems) / numberOfItemsInRow)
        
        return Int(numberOfRows)
    }
}
