import UIKit
import MapboxCoreNavigation
import MapboxDirections
import Mapbox

class OfflineServiceViewController: UITableViewController {

    private typealias ActionHandler = (UIAlertAction) -> Void

    private var offlineRegions = [OfflineRegion]()
    
    // MARK: - UIViewController delegate methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupOfflineService()
    }

    // MARK: - Setting-up methods
    
    private func setupUI() {
        tableView.register(UINib(nibName: OfflineRegionTableViewCell.identifier, bundle: nil),
                           forCellReuseIdentifier: OfflineRegionTableViewCell.identifier)
        
        tableView.separatorInset = .zero
        tableView.allowsSelection = true
        
        title = OfflineServiceConstants.title
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "settings"),
                                                           style: .plain,
                                                           target: self,
                                                           action: #selector(showSettings))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: OfflineServiceConstants.close,
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(dismissViewController))
    }
    
    private func setupOfflineService() {
        OfflineService.shared.register(observer: self)
        OfflineService.shared.fetchAvailableRegions() { [weak self] regions,fetchError in
            guard let self = self else { return }
            if let error = fetchError {
                self.presentAlert(OfflineServiceConstants.title, message: error.message)
                return
            }
            self.show(regions: regions)
        }
    }
    
    // MARK: - Action handler methods
    
    @objc private func dismissViewController() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func showSettings() {
        let alertController = UIAlertController(title: OfflineServiceConstants.title,
                                                message: OfflineServiceConstants.selectActionTitle,
                                                preferredStyle: .alert)
        
        let clearMapsAmbientCacheActionHandler: ActionHandler = { _ in
            clearMapsAmbientCache()
        }
        
        let clearNavigationAmbientCacheActionHandler: ActionHandler = { _ in
            clearNavigationAmbientCache()
        }
        
        let actionPayloads: [(String, UIAlertAction.Style, ActionHandler?)] = [
            (OfflineServiceConstants.clearMapsAmbientCache, .default, clearMapsAmbientCacheActionHandler),
            (OfflineServiceConstants.clearNavigationAmbientCache, .default, clearNavigationAmbientCacheActionHandler),
            (OfflineServiceConstants.cancel, .cancel, nil)
        ]
        
        actionPayloads
            .map({ payload in UIAlertAction(title: payload.0, style: payload.1, handler: payload.2) })
            .forEach(alertController.addAction(_:))
        
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - OfflineRegion entities management methods

    func show(regions: [OfflineRegion]) {
        offlineRegions = regions
        tableView.reloadData()
    }

    func update(region: OfflineRegion) {
        for index in 0..<offlineRegions.count {
            let showedRegion = offlineRegions[index]
            if showedRegion.id == region.id {
                offlineRegions[index] = region
                tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                return
            }
        }
        offlineRegions.append(region)
        tableView.beginUpdates()
        tableView.insertRows(at: [IndexPath(row: offlineRegions.count - 1, section: 0)], with: .automatic)
        tableView.endUpdates()
    }

    func showDownloadProgress(for region: OfflineRegion) {
        for index in 0..<offlineRegions.count {
            if offlineRegions[index].id == region.id {
                let indexPath = IndexPath(row: index, section: 0)
                let cell = self.tableView.cellForRow(at: indexPath) as? OfflineRegionTableViewCell
                cell?.updateDownloadProgress(for: region)
                return
            }
        }
    }

    func remove(region: OfflineRegion) {
        var indexesToRemove: [IndexPath] = []

        for index in 0..<offlineRegions.count {
            let showedRegion = offlineRegions[index]
            if showedRegion.id == region.id {
                indexesToRemove.append(IndexPath(row: index, section: 0))
            }
        }

        indexesToRemove.forEach { index in
            offlineRegions.remove(at: index.row)
        }

        tableView.beginUpdates()
        tableView.deleteRows(at: indexesToRemove, with: .automatic)
        tableView.endUpdates()
    }

    // MARK: - UITableView delegate methods
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: OfflineRegionTableViewCell.identifier, for: indexPath) as! OfflineRegionTableViewCell
        cell.presentUI(for: offlineRegions[indexPath.row])

        return cell
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return offlineRegions.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 240.0
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let offlineRegion = offlineRegions[indexPath.row]
        showActions(offlineRegion)
    }
    
    // MARK: - Private methods

    private func showActions(_ offlineRegion: OfflineRegion) {
        let alertController = UIAlertController(title: OfflineServiceConstants.title,
                                                message: OfflineServiceConstants.selectActionTitle,
                                                preferredStyle: .alert)

        var mapsPackTitle = OfflineServiceConstants.downloadMapsPack
        var mapsActionHandler: ActionHandler = { _ in
            OfflineService.shared.download(region: offlineRegion, forDomain: .maps)
        }

        if offlineRegion.mapsPack?.status == .available {
            mapsPackTitle = OfflineServiceConstants.deleteMapsPack
            mapsActionHandler = { _ in
                OfflineService.shared.remove(region: offlineRegion, forDomain: .maps)
            }
        }
        if offlineRegion.mapsPack?.status == .downloading {
            mapsPackTitle = OfflineServiceConstants.pauseDownloadingMapsPack
            mapsActionHandler = { _ in
                OfflineService.shared.cancelDownload(for: offlineRegion, domain: .maps)
            }
        }
        if offlineRegion.mapsPack?.status == .pending {
            mapsPackTitle = OfflineServiceConstants.continueDownloadingMapsPack
            mapsActionHandler = { _ in
                OfflineService.shared.download(region: offlineRegion, forDomain: .maps)
            }
        }

        var navigationPackTitle = OfflineServiceConstants.downloadNavigationPack
        var navigationActionHandler: ActionHandler = { _ in
            OfflineService.shared.download(region: offlineRegion, forDomain: .navigation)
        }

        if offlineRegion.navigationPack?.status == .available {
            navigationPackTitle = OfflineServiceConstants.deleteNavigationPack
            navigationActionHandler = { _ in
                OfflineService.shared.remove(region: offlineRegion, forDomain: .navigation)
            }
        }
        if offlineRegion.navigationPack?.status == .downloading {
            navigationPackTitle = OfflineServiceConstants.pauseDownloadingNavigationPack
            navigationActionHandler = { _ in
                OfflineService.shared.cancelDownload(for: offlineRegion, domain: .navigation)
            }
        }
        if offlineRegion.navigationPack?.status == .pending {
            navigationPackTitle = OfflineServiceConstants.continueDownloadingNavigationPack
            navigationActionHandler = { _ in
                OfflineService.shared.download(region: offlineRegion, forDomain: .navigation)
            }
        }

        let actionPayloads: [(String, UIAlertAction.Style, ActionHandler?)] = [
            (mapsPackTitle, .default, mapsActionHandler),
            (navigationPackTitle, .default, navigationActionHandler),
            (OfflineServiceConstants.cancel, .cancel, nil)
        ]

        actionPayloads
            .map({ payload in UIAlertAction(title: payload.0, style: payload.1, handler: payload.2) })
            .forEach(alertController.addAction(_:))

        present(alertController, animated: true, completion: nil)
    }
}

extension OfflineServiceViewController: MapboxCoreNavigation.OfflineServiceObserver {
    func didBecomeAvailable(region: OfflineRegion, forDomain: OfflineRegionDomain) {
        update(region: region)
    }

    func didBecomeUnavailable(region: OfflineRegion) {
        remove(region: region)
    }

    func didDelete(region: OfflineRegion, forDomain: OfflineRegionDomain) {
        update(region: region)
    }

    func didStartDownloading(region: OfflineRegion, forDomain: OfflineRegionDomain) {
        showDownloadProgress(for: region)
    }

    func didBecomeErrored(region: OfflineRegion, forDomain: OfflineRegionDomain, withError error: OfflineRegionError?) {
        self.presentAlert(OfflineServiceConstants.title, message: "Error occured for: \(region.id)")
    }
}
