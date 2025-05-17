import UIKit
import CoreLocation

class LocationListViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var sortSegmentedControl: UISegmentedControl!
    
    // MARK: - Properties
    private var locations: [Location] = []
    private let dataManager = DataManager.shared
    private let locationManager = LocationManager.shared
    private var currentLocation: CLLocation?
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupSegmentedControl()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Reload locations from local storage
        loadLocations()
    }
    
    // MARK: - Setup Methods
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "LocationCell", bundle: nil), forCellReuseIdentifier: "LocationCell")
    }
    
    private func setupSegmentedControl() {
        sortSegmentedControl.removeAllSegments()
        sortSegmentedControl.insertSegment(withTitle: "Distance", at: 0, animated: false)
        sortSegmentedControl.insertSegment(withTitle: "Status", at: 1, animated: false)
        sortSegmentedControl.insertSegment(withTitle: "Date", at: 2, animated: false)
        sortSegmentedControl.selectedSegmentIndex = 0
        
        sortSegmentedControl.addTarget(self, action: #selector(sortChanged(_:)), for: .valueChanged)
    }
    
    // MARK: - Data Methods
    
    private func loadLocations() {
        locations = dataManager.loadLocationsFromLocal()
        
        // Get current location for sorting
        locationManager.getCurrentLocation { [weak self] location in
            self?.currentLocation = location
            self?.sortLocations()
        }
    }
    
    private func sortLocations() {
        switch sortSegmentedControl.selectedSegmentIndex {
        case 0: // Distance
            if let currentLocation = currentLocation {
                locations = locationManager.sortLocationsByDistance(locations: locations, from: currentLocation)
            } else {
                // Fall back to date sorting if location is not available
                locations.sort { $0.createdAt > $1.createdAt }
            }
            
        case 1: // Status
            locations.sort { loc1, loc2 in
                // Sort by status: not visited first, then completed, then inaccessible
                if loc1.status == loc2.status {
                    return loc1.title < loc2.title
                }
                
                switch (loc1.status, loc2.status) {
                case (.notVisited, _): return true
                case (_, .notVisited): return false
                case (.completed, .inaccessible): return true
                case (.inaccessible, .completed): return false
                default: return true
                }
            }
            
        case 2: // Date
            locations.sort { $0.createdAt > $1.createdAt }
            
        default:
            break
        }
        
        tableView.reloadData()
    }
    
    // MARK: - Action Methods
    
    @objc private func sortChanged(_ sender: UISegmentedControl) {
        sortLocations()
    }
    
    private func navigateToLocationDetail(_ location: Location) {
        // Navigate to location detail view controller
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "LocationDetailViewController") as? LocationDetailViewController {
            detailVC.location = location
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension LocationListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "LocationCell", for: indexPath) as? LocationCell else {
            return UITableViewCell()
        }
        
        let location = locations[indexPath.row]
        cell.configure(with: location)
        
        // Calculate distance if current location is available
        if let currentLocation = currentLocation {
            let locationCoordinate = CLLocation(latitude: location.latitude, longitude: location.longitude)
            let distance = currentLocation.distance(from: locationCoordinate)
            cell.setDistance(distance)
        } else {
            cell.setDistance(nil)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let location = locations[indexPath.row]
        navigateToLocationDetail(location)
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let location = locations[indexPath.row]
        
        // Delete action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (_, _, completion) in
            guard let self = self else { return }
            
            // Show confirmation alert
            let alert = UIAlertController(title: "Delete Location", message: "Are you sure you want to delete this location?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completion(false)
            })
            
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                self.dataManager.deleteLocation(withId: location.id)
                self.locations.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                completion(true)
            })
            
            self.present(alert, animated: true)
        }
        
        // Status actions
        let statusActions = self.createStatusActions(for: location, at: indexPath)
        
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction] + statusActions)
        return configuration
    }
    
    private func createStatusActions(for location: Location, at indexPath: IndexPath) -> [UIContextualAction] {
        var actions: [UIContextualAction] = []
        
        // Only show status actions that are different from current status
        if location.status != .notVisited {
            let notVisitedAction = UIContextualAction(style: .normal, title: "Not Visited") { [weak self] (_, _, completion) in
                guard let self = self else { return }
                
                var updatedLocation = location
                updatedLocation.updateStatus(.notVisited)
                self.dataManager.updateLocation(updatedLocation)
                self.locations[indexPath.row] = updatedLocation
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
                completion(true)
            }
            notVisitedAction.backgroundColor = .systemBlue
            actions.append(notVisitedAction)
        }
        
        if location.status != .completed {
            let completedAction = UIContextualAction(style: .normal, title: "Completed") { [weak self] (_, _, completion) in
                guard let self = self else { return }
                
                var updatedLocation = location
                updatedLocation.updateStatus(.completed)
                self.dataManager.updateLocation(updatedLocation)
                self.locations[indexPath.row] = updatedLocation
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
                completion(true)
            }
            completedAction.backgroundColor = .systemGreen
            actions.append(completedAction)
        }
        
        if location.status != .inaccessible {
            let inaccessibleAction = UIContextualAction(style: .normal, title: "Inaccessible") { [weak self] (_, _, completion) in
                guard let self = self else { return }
                
                var updatedLocation = location
                updatedLocation.updateStatus(.inaccessible)
                self.dataManager.updateLocation(updatedLocation)
                self.locations[indexPath.row] = updatedLocation
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
                completion(true)
            }
            inaccessibleAction.backgroundColor = .systemRed
            actions.append(inaccessibleAction)
        }
        
        return actions
    }
}
