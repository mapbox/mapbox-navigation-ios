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
    
    @IBOutlet weak var mapsDownloadProgressContainerStackView: UIStackView!
    @IBOutlet weak var mapsDownloadProgressLabel: UILabel!
    @IBOutlet weak var mapsDownloadProgressView: UIProgressView!
    
    var mapsDownloadProgressContainerHeightConstraint: NSLayoutConstraint? = nil
    
    @IBOutlet weak var navigationDownloadProgressContainerStackView: UIStackView!
    @IBOutlet weak var navigationDownloadProgressLabel: UILabel!
    @IBOutlet weak var navigationDownloadProgressView: UIProgressView!
    
    var navigationDownloadProgressContainerHeightConstraint: NSLayoutConstraint? = nil
    
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
    
    // MARK: - Public UI update related methods
    
    func showDownloadProgress(for domain: OfflineDataDomain, dataPack: OfflineDataPack, metadata: OfflineDataRegionMetadata) {
        DispatchQueue.main.async {
            self.updateDownloadProgressContainerHeight(for: domain, constant: 25.0)
            
            if domain == .maps, let mapPack = metadata.mapPack {
                self.mapsDownloadProgressView.progress = Float(dataPack.bytes) / Float(mapPack.bytes)
                self.mapsDownloadProgressLabel.text = "\(OfflineDataRegionTableViewCell.byteCountFormatter.string(fromByteCount: Int64(dataPack.bytes))) / \(OfflineDataRegionTableViewCell.byteCountFormatter.string(fromByteCount: Int64(mapPack.bytes)))"
            } else if domain == .navigation, let navigationPack = metadata.navigationPack {
                self.navigationDownloadProgressView.progress = Float(dataPack.bytes) / Float(navigationPack.bytes)
                self.navigationDownloadProgressLabel.text = "\(OfflineDataRegionTableViewCell.byteCountFormatter.string(fromByteCount: Int64(dataPack.bytes))) / \(OfflineDataRegionTableViewCell.byteCountFormatter.string(fromByteCount: Int64(navigationPack.bytes)))"
            }
        }
    }
    
    func presentUI(for offlineDataItem: OfflineDataItem) {
        DispatchQueue.main.async {
            self.updateDownloadProgressContainerHeight(constant: 0.0)
            
            self.identifierLabel.text = offlineDataItem.dataRegionMetadata.id
            self.lastUpdatedLabel.text = "\(OfflineServiceConstants.lastUpdated): \(OfflineDataRegionTableViewCell.dateFormatter.string(from: offlineDataItem.dataRegionMetadata.last_updated))"
            
            if let mapPack = offlineDataItem.dataRegionMetadata.mapPack {
                self.mapsPackLastUpdatedLabel.text = "\(OfflineServiceConstants.lastUpdated): \(mapPack.data_version)"
                self.mapsPackSizeLabel.text = "\(OfflineServiceConstants.size): \(OfflineDataRegionTableViewCell.byteCountFormatter.string(fromByteCount: Int64(mapPack.bytes)))"
            }
            
            if offlineDataItem.mapPackMetadata != nil {
                self.mapsPackLabel.textColor = .green
            }
            
            if let navigationPack = offlineDataItem.dataRegionMetadata.navigationPack {
                self.navigationPackLastUpdatedLabel.text = "\(OfflineServiceConstants.lastUpdated): \(navigationPack.data_version)"
                self.navigationPackSizeLabel.text = "\(OfflineServiceConstants.size): \(OfflineDataRegionTableViewCell.byteCountFormatter.string(fromByteCount: Int64(navigationPack.bytes)))"
            }
            
            if offlineDataItem.navigationPackMetadata != nil {
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
        
        mapsPackLabel.text = OfflineServiceConstants.mapsPack
        mapsPackLabel.font = UIFont.systemFont(ofSize: 13.0)
        mapsPackLabel.textColor = .red
        
        mapsPackLastUpdatedLabel.text = ""
        mapsPackLastUpdatedLabel.font = UIFont.systemFont(ofSize: 11.0)
        mapsPackLastUpdatedLabel.textColor = .darkGray
        
        mapsPackSizeLabel.text = ""
        mapsPackSizeLabel.font = UIFont.systemFont(ofSize: 11.0)
        mapsPackSizeLabel.textColor = .darkGray
        
        navigationPackLabel.text = OfflineServiceConstants.navigationPack
        navigationPackLabel.font = UIFont.systemFont(ofSize: 13.0)
        navigationPackLabel.textColor = .red
        
        navigationPackLastUpdatedLabel.text = ""
        navigationPackLastUpdatedLabel.font = UIFont.systemFont(ofSize: 11.0)
        navigationPackLastUpdatedLabel.textColor = .darkGray
        
        navigationPackSizeLabel.text = ""
        navigationPackSizeLabel.font = UIFont.systemFont(ofSize: 11.0)
        navigationPackSizeLabel.textColor = .darkGray
        
        mapsDownloadProgressLabel.text = ""
        mapsDownloadProgressLabel.font = UIFont.systemFont(ofSize: 11.0)
        mapsDownloadProgressLabel.textColor = .darkGray
        mapsDownloadProgressLabel.textAlignment = .center
        
        mapsDownloadProgressView.progress = 0.0
        
        navigationDownloadProgressLabel.text = ""
        navigationDownloadProgressLabel.font = UIFont.systemFont(ofSize: 11.0)
        navigationDownloadProgressLabel.textColor = .darkGray
        navigationDownloadProgressLabel.textAlignment = .center
        
        navigationDownloadProgressView.progress = 0.0
    }
    
    private func setupConstraints() {
        mapsDownloadProgressContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        mapsDownloadProgressContainerHeightConstraint = NSLayoutConstraint(item: mapsDownloadProgressContainerStackView!,
                                                                           attribute: .height,
                                                                           relatedBy: .equal,
                                                                           toItem: nil,
                                                                           attribute: .notAnAttribute,
                                                                           multiplier: 0.0,
                                                                           constant: 0)
        mapsDownloadProgressContainerHeightConstraint?.isActive = true
        
        navigationDownloadProgressContainerStackView.translatesAutoresizingMaskIntoConstraints = false
        navigationDownloadProgressContainerHeightConstraint = NSLayoutConstraint(item: navigationDownloadProgressContainerStackView!,
                                                                                 attribute: .height,
                                                                                 relatedBy: .equal,
                                                                                 toItem: nil,
                                                                                 attribute: .notAnAttribute,
                                                                                 multiplier: 0.0,
                                                                                 constant: 0)
        navigationDownloadProgressContainerHeightConstraint?.isActive = true
    }
    
    private func updateDownloadProgressContainerHeight(for domain: OfflineDataDomain? = nil, constant: CGFloat) {
        switch domain {
        case .maps:
            if self.mapsDownloadProgressContainerHeightConstraint?.constant != constant {
                self.mapsDownloadProgressContainerHeightConstraint?.constant = constant
            }
        case .navigation:
            if self.navigationDownloadProgressContainerHeightConstraint?.constant != constant {
                self.navigationDownloadProgressContainerHeightConstraint?.constant = constant
            }
        case .none:
            self.mapsDownloadProgressContainerHeightConstraint?.constant = constant
            self.navigationDownloadProgressContainerHeightConstraint?.constant = constant
        }
    }
}
