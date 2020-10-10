import UIKit
import MapboxCommon

class OfflineDataRegionTableViewCell: UITableViewCell {
    
    static let identifier = String(describing: OfflineDataRegionTableViewCell.self)
    
    @IBOutlet weak var containerStackView: UIStackView!
    
    @IBOutlet weak var identifierLabel: UILabel!
    @IBOutlet weak var lastUpdatedLabel: UILabel!
    
    @IBOutlet weak var mapsPackLabel: UILabel!
    @IBOutlet weak var mapsPackLastUpdatedLabel: UILabel!
    @IBOutlet weak var mapsPackSizeLabel: UILabel!
    
    @IBOutlet weak var navigationPackLabel: UILabel!
    @IBOutlet weak var navigationPackLastUpdatedLabel: UILabel!
    @IBOutlet weak var navigationPackSizeLabel: UILabel!
    
    // TODO: Improve UI for simultaneous downloads of Maps and Navigation packs.
    @IBOutlet weak var downloadProgressContainerStackView: UIStackView!
    @IBOutlet weak var downloadProgressLabel: UILabel!
    @IBOutlet weak var downloadProgressView: UIProgressView!
    
    var downloadProgressContainerHeightConstraint: NSLayoutConstraint? = nil
    
    static var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
        
        return dateFormatter
    }()
    
    static var byteCountFormatter: ByteCountFormatter = {
        let byteCountFormatter = ByteCountFormatter()
        byteCountFormatter.allowedUnits = .useMB
        
        return byteCountFormatter
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupUI()
        setupConstraints()
    }
    
    override func prepareForReuse() {
        setupUI()
    }
    
    // MARK: Public UI update related methods
    
    func showDownloadProgress(for domain: OfflineDataDomain, dataPack: OfflineDataPack, metadata: OfflineDataRegionMetadata) {
        DispatchQueue.main.async {
            self.updateDownloadProgressContainerHeight(constant: 25.0)
            
            var totalSize: Int64? = nil
            if domain == .maps, let mapPack = metadata.mapPack {
                totalSize = Int64(mapPack.bytes)
            } else if domain == .navigation, let navigationPack = metadata.navigationPack {
                totalSize = Int64(navigationPack.bytes)
            }
            
            if let totalSize = totalSize {
                self.downloadProgressView.progress = Float(dataPack.bytes) / Float(totalSize)
                self.downloadProgressLabel.text = "\(OfflineDataRegionTableViewCell.byteCountFormatter.string(fromByteCount: Int64(dataPack.bytes))) / \(OfflineDataRegionTableViewCell.byteCountFormatter.string(fromByteCount: totalSize))"
            }
        }
    }
    
    func presentUI(for offlineDataRegion: OfflineDataItem) {
        DispatchQueue.main.async {
            self.updateDownloadProgressContainerHeight(constant: 0.0)
            
            self.identifierLabel.text = offlineDataRegion.dataRegionMetadata.id
            self.lastUpdatedLabel.text = "Last updated: \(OfflineDataRegionTableViewCell.dateFormatter.string(from: offlineDataRegion.dataRegionMetadata.last_updated))"
            
            if let mapPack = offlineDataRegion.dataRegionMetadata.mapPack {
                self.mapsPackLastUpdatedLabel.text = "Last updated: \(mapPack.data_version)"
                self.mapsPackSizeLabel.text = "Size: \(OfflineDataRegionTableViewCell.byteCountFormatter.string(fromByteCount: Int64(mapPack.bytes)))"
            }
            
            if offlineDataRegion.mapPackMetadata != nil {
                self.mapsPackLabel.textColor = .green
            }
            
            if let navigationPack = offlineDataRegion.dataRegionMetadata.navigationPack {
                self.navigationPackLastUpdatedLabel.text = "Last updated: \(navigationPack.data_version)"
                self.navigationPackSizeLabel.text = "Size: \(OfflineDataRegionTableViewCell.byteCountFormatter.string(fromByteCount: Int64(navigationPack.bytes)))"
            }
            
            if offlineDataRegion.navigationPackMetadata != nil {
                self.navigationPackLabel.textColor = .green
            }
        }
    }
    
    // MARK: - Private methods
    
    private func setupUI() {
        containerStackView.spacing = 2.0
        
        identifierLabel.font = UIFont.systemFont(ofSize: 17.0)
        
        lastUpdatedLabel.font = UIFont.systemFont(ofSize: 11.0)
        lastUpdatedLabel.textColor = .darkGray
        
        mapsPackLabel.text = "Maps pack"
        mapsPackLabel.font = UIFont.systemFont(ofSize: 13.0)
        mapsPackLabel.textColor = .red
        
        mapsPackLastUpdatedLabel.text = ""
        mapsPackLastUpdatedLabel.font = UIFont.systemFont(ofSize: 11.0)
        mapsPackLastUpdatedLabel.textColor = .darkGray
        
        mapsPackSizeLabel.text = ""
        mapsPackSizeLabel.font = UIFont.systemFont(ofSize: 11.0)
        mapsPackSizeLabel.textColor = .darkGray
        
        navigationPackLabel.text = "Navigation pack"
        navigationPackLabel.font = UIFont.systemFont(ofSize: 13.0)
        navigationPackLabel.textColor = .red
        
        navigationPackLastUpdatedLabel.text = ""
        navigationPackLastUpdatedLabel.font = UIFont.systemFont(ofSize: 11.0)
        navigationPackLastUpdatedLabel.textColor = .darkGray
        
        navigationPackSizeLabel.text = ""
        navigationPackSizeLabel.font = UIFont.systemFont(ofSize: 11.0)
        navigationPackSizeLabel.textColor = .darkGray
        
        downloadProgressLabel.text = ""
        downloadProgressLabel.font = UIFont.systemFont(ofSize: 11.0)
        downloadProgressLabel.textColor = .darkGray
        downloadProgressLabel.textAlignment = .center
        
        downloadProgressView.progress = 0.0
    }
    
    private func setupConstraints() {
        downloadProgressContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        downloadProgressContainerHeightConstraint = NSLayoutConstraint(item: downloadProgressContainerStackView!,
                                                                       attribute: .height,
                                                                       relatedBy: .equal,
                                                                       toItem: nil,
                                                                       attribute: .notAnAttribute,
                                                                       multiplier: 0.0,
                                                                       constant: 0)
        downloadProgressContainerHeightConstraint?.isActive = true
    }
    
    private func updateDownloadProgressContainerHeight(constant: CGFloat) {
        if self.downloadProgressContainerHeightConstraint?.constant != constant {
            self.downloadProgressContainerHeightConstraint?.constant = constant
        }
    }
}
