import UIKit

extension UICollectionView {
    func numberOfRows(using delegate: UIViewController & UICollectionViewDelegateFlowLayout) -> Int {
        let layout = (collectionViewLayout as? UICollectionViewFlowLayout)!
        
        var totalNumberOfItems = 0
        for section in 0...numberOfSections - 1 {
            totalNumberOfItems += numberOfItems(inSection: section)
        }
        
        let insets = layout.sectionInset
        let width = bounds.width - insets.left - insets.right
        let indexPath = IndexPath(row: 0, section: 0)
        let cellWidth = delegate.collectionView!(self, layout: layout, sizeForItemAt: indexPath).width
        let cellSpacing = layout.minimumInteritemSpacing
        let numberOfItemsInRow = floor(width / (cellWidth + cellSpacing))
        let numberOfRows = ceil(CGFloat(totalNumberOfItems) / numberOfItemsInRow)
        
        return Int(numberOfRows)
    }
}
