//
//  IssuesListViewController.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import UIKit
import CoreData
import SeeClickFix
import CoreLocation

class IssuesListCell : UICollectionViewCell {
    @IBOutlet var summmary: UILabel?
    @IBOutlet var imageView: UIImageView?
}

class IssuesListViewController : UIViewController {
    private struct Constants {
        fileprivate static let cellIdentifier = "Cell"
    }
    lazy var fetchResultsControllerCollectionViewAdapter: FRCCollectionView<Issue> = {
        let fetchRequest: NSFetchRequest<Issue>
        do {
            fetchRequest = try Issue.fetchRequest()
        } catch {
            preconditionFailure()
        }
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        let moc = DataStore.shared.reader
        var frc = FRC(fetchRequest: fetchRequest, managedObjectContext: moc, cacheName: "IssueListCache")
        return FRCCollectionView(fetchedResultsController: frc) { [weak self] () -> UICollectionView? in
            return self?.collectionView
        }
    }()
    var fetchedResultsController: FRC<Issue> {
        get {
            return self.fetchResultsControllerCollectionViewAdapter.fetchedResultsController
        }
    }
    @IBOutlet var collectionView: UICollectionView?
    var location = LocationAdapter()
    override func viewDidLoad() {
        super.viewDidLoad()
        location.didUpdateLocations = { [weak self] manager, locations in
            guard let location = locations.first else {
                return
            }
            let geoCoder = CLGeocoder()
            geoCoder.reverseGeocodeLocation(location) { placemarks, _ in
                if let postalCode = placemarks?.first?.postalCode {
                    self?.update(postalCode: postalCode)
                } else {
                    self?.update(postalCode: nil)
                }
            }
        }
        location.clients = [Clients.issuesList]
        location.start()
    }
    var currentPostalCode: String? {
        didSet {
            if let postalCode = currentPostalCode {
                update(location: Address(address: postalCode))
            }
        }
    }
    func update(postalCode: String?) {
        if let postalCode = postalCode, let currentPostalCode = currentPostalCode  {
            if postalCode != currentPostalCode {
                self.currentPostalCode = postalCode
            }
        } else {
            currentPostalCode = postalCode
        }
    }
    func update(location: SeeClickFix.Location) {
        Coordinator.shared.issues(location: location, page: 0, count: 20)
    }
}

extension IssuesListViewController : UICollectionViewDelegate {
    
}

extension IssuesListViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        do {
            return try fetchedResultsController.count(section: section)
        } catch {
            return 0
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.cellIdentifier, for: indexPath) as? IssuesListCell {
            let issue = fetchedResultsController.object(at: indexPath)
            cell.summmary?.text = issue.summary
            return cell
        }
        preconditionFailure()
    }
}
