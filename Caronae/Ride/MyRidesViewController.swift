import UIKit
import RealmSwift

class MyRidesViewController: RideListController {
    var notificationTokens: [NotificationToken?] = []
    var unreadNotifications: Results<Notification>!
    var ridesRealm: Results<Ride>!
    
    var sectionRides = [Results<Ride>]()
    let sectionTitles = ["Pendentes", "Ativas", "Ofertadas"]
    
    override func viewDidLoad() {
        let realm = try! Realm()
        ridesRealm = realm.objects(Ride.self).filter("FALSEPREDICATE")
        
        hidesDirectionControl = true
        super.viewDidLoad()
        
        self.navigationController?.view.backgroundColor = UIColor.white
        navigationItem.titleView = UIImageView(image: UIImage(named: "NavigationBarLogo"))
        
        RideService.instance.getMyRides(success: { pending, active, offered in
            self.sectionRides = [pending, active, offered]
            self.subscribeToChanges()
        }, error: { error in
            self.loadingFailed(withError: error as NSError)
        })
        
        changeBackgroundIfNeeded()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateNotificationBadges), name: .CaronaeDidUpdateNotifications, object: nil)
        updateNotificationBadges()
    }
    
    deinit {
        notificationTokens.forEach { $0?.invalidate() }
        NotificationCenter.default.removeObserver(self)
    }
    
    override func refreshTable() {
        RideService.instance.updateMyRides(success: {
            self.refreshControl?.endRefreshing()
            NSLog("My rides updated")
        }, error: { error in
            self.refreshControl?.endRefreshing()
            NSLog("Error updating my rides (\(error.localizedDescription))")
        })
    }
    
    func subscribeToChanges() {
        // Open issue: Support grouping in RLMResults
        // https://github.com/realm/realm-cocoa/issues/3384
        
        let pending = sectionRides[0]
        let active  = sectionRides[1]
        let offered = sectionRides[2]
        
        let pendingNotificationToken = pending.observe { [weak self] (changes: RealmCollectionChange) in
            guard let tableView = self?.tableView else { return }
            
            tableView.reloadData()
            self?.changeBackgroundIfNeeded()
        }
        
        let activeNotificationToken = active.observe { [weak self] (changes: RealmCollectionChange) in
            guard let tableView = self?.tableView else { return }
            
            tableView.tableFooterView = active.isEmpty ? nil : self?.tableFooter
            tableView.reloadData()
            self?.changeBackgroundIfNeeded()
        }
        
        let offeredNotificationToken = offered.observe { [weak self] (changes: RealmCollectionChange) in
            guard let tableView = self?.tableView else { return }
            
            tableView.reloadData()
            self?.changeBackgroundIfNeeded()
        }
        
        notificationTokens.append(contentsOf: [pendingNotificationToken, activeNotificationToken, offeredNotificationToken])
    }
    
    @objc func updateNotificationBadges() {
        unreadNotifications = try! NotificationService.instance.getNotifications(of: [.chat, .rideJoinRequest, .rideJoinRequestAccepted])
        if unreadNotifications.isEmpty {
            navigationController?.tabBarItem.badgeValue = nil
        } else {
            navigationController?.tabBarItem.badgeValue = String(format: "%ld", unreadNotifications.count)
        }
        tableView.reloadData()
    }
    
    func changeBackgroundIfNeeded() {
        tableView.backgroundView = (sectionRides.contains(where: { !$0.isEmpty })) ? nil : emptyTableLabel
    }
    
    func openChatForRide(withID rideID: Int) {
        guard let ride = RideService.instance.getRideFromRealm(withID: rideID) else {
            NSLog("Tried to open chat for ride %@, but did not ride on realm.", rideID)
            return
        }
        
        let rideViewController = RideViewController.instance(for: ride)
        rideViewController.shouldOpenChatWindow = true
        _ = navigationController?.popToRootViewController(animated: false)
        navigationController?.pushViewController(rideViewController, animated: true)
    }

    
    // MARK: Table methods
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView!, titleForHeaderInSection section: Int) -> String! {
        guard !sectionRides[section].isEmpty else {
            return nil
        }
        
        return sectionTitles[section]
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionRides[section].count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let ride = sectionRides[indexPath.section][indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Ride Cell", for: indexPath) as! RideCell
        cell.configureCell(with: ride)
        cell.badgeCount = unreadNotifications.filter("rideID == %@", ride.id).count
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let ride = sectionRides[indexPath.section][indexPath.row]
        let rideVC = RideViewController.instance(for: ride)
        self.navigationController?.show(rideVC, sender: self)
    }
    
    lazy var tableFooter: UIView = {
        let tableFooter = UILabel(frame: CGRect(x: 0, y: 0, width: 300, height: 40))
        tableFooter.text = "Se você é motorista de alguma carona, não\n esqueça de concluí-la após seu término. :)"
        tableFooter.numberOfLines = 0
        tableFooter.backgroundColor = .white
        tableFooter.font = .systemFont(ofSize: 10)
        tableFooter.textColor = .lightGray
        tableFooter.textAlignment = .center
        return tableFooter
    }()
    
}
