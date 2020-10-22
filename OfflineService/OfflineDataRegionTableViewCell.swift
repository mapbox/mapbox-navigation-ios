import UIKit
import MapboxCoreNavigation

class OfflineRegionTableViewCell: UITableViewCell {
    
    static let identifier = String(describing: OfflineRegionTableViewCell.self)
    
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

    func showDownloadProgress(for domain: OfflineRegionDomain, dataPack: OfflineRegionPack, region: OfflineRegion) {
        self.updateDownloadProgressContainerHeight(for: domain, constant: 25.0)

        if let totalSize = dataPack.totalBytes {
            if domain == .maps {
                self.mapsDownloadProgressView.progress = Float(dataPack.downloadedBytes) / Float(totalSize)
                self.mapsDownloadProgressLabel.text = "\(OfflineRegionTableViewCell.byteCountFormatter.string(fromByteCount: Int64(dataPack.downloadedBytes))) / \(OfflineRegionTableViewCell.byteCountFormatter.string(fromByteCount: Int64(totalSize)))"
            } else {
                self.navigationDownloadProgressView.progress = Float(dataPack.downloadedBytes) / Float(totalSize)
                self.navigationDownloadProgressLabel.text = "\(OfflineRegionTableViewCell.byteCountFormatter.string(fromByteCount: Int64(dataPack.downloadedBytes))) / \(OfflineRegionTableViewCell.byteCountFormatter.string(fromByteCount: Int64(totalSize)))"
            }
        }
    }

    func updateDownloadProgress(for region: OfflineRegion) {
        DispatchQueue.main.async {
            if let mapsPack = region.mapsPack, mapsPack.status == .downloading || mapsPack.status == .incomplete {
                self.showDownloadProgress(for: .maps, dataPack: mapsPack, region: region)
            }
            if let navigationPack = region.navigationPack, navigationPack.status == .downloading || navigationPack.status == .incomplete {
                self.showDownloadProgress(for: .navigation, dataPack: navigationPack, region: region)
            }
        }
    }

    func presentUI(for region: OfflineRegion) {
        DispatchQueue.main.async {
            self.updateDownloadProgressContainerHeight(constant: 0.0)

            self.identifierLabel.text = region.id
            self.lastUpdatedLabel.text = "\(OfflineServiceConstants.lastUpdated): \(OfflineRegionTableViewCell.dateFormatter.string(from: region.lastUpdated))"

            if let mapPack = region.mapsPack {
                self.mapsPackLastUpdatedLabel.text = "\(OfflineServiceConstants.lastUpdated): \(mapPack.dataVersion ?? "")"
                self.mapsPackSizeLabel.text = "\(OfflineServiceConstants.size): \(OfflineRegionTableViewCell.byteCountFormatter.string(fromByteCount: Int64(mapPack.totalBytes ?? 0)))"

                if mapPack.status == .downloading || mapPack.status == .incomplete {
                    self.showDownloadProgress(for: .maps, dataPack: mapPack, region: region)
                }
            }

            if region.mapsPack?.status == .available {
                self.mapsPackLabel.textColor = .green
            }

            if let navigationPack = region.navigationPack {
                self.navigationPackLastUpdatedLabel.text = "\(OfflineServiceConstants.lastUpdated): \(navigationPack.dataVersion ?? "")"
                self.navigationPackSizeLabel.text = "\(OfflineServiceConstants.size): \(OfflineRegionTableViewCell.byteCountFormatter.string(fromByteCount: Int64(navigationPack.totalBytes ?? 0)))"

                if navigationPack.status == .downloading || navigationPack.status == .incomplete {
                    self.showDownloadProgress(for: .navigation, dataPack: navigationPack, region: region)
                }
            }

            if region.navigationPack?.status == .available {
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
    
    private func updateDownloadProgressContainerHeight(for domain: OfflineRegionDomain? = nil, constant: CGFloat) {
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
