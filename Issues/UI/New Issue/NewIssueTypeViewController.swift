//
//  NewIssueTypeViewController.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import UIKit
import CoreData
import CoreLocation
import SeeClickFix

class NewIssueTypeCell : UICollectionViewCell {
    @IBOutlet var title: UILabel?
    override func prepareForReuse() {
        super.prepareForReuse()
        title?.text = nil
    }
}

class NewIssueTypeOrganizationHeader : UICollectionReusableView {
    @IBOutlet var title: UILabel?
    override func prepareForReuse() {
        super.prepareForReuse()
        title?.text = nil
    }
}

extension Point {
    init(location: CLLocation) {
        self.init(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }
}

class NewIssueTypeViewController : UIViewController {
    private struct Constants {
        fileprivate static let cellIdentifier = "Cell"
    }
    lazy var fetchResultsControllerCollectionViewAdapter: FRCCollectionView<ReportType> = {
        let fetchRequest: NSFetchRequest<ReportType>
        do {
            fetchRequest = try ReportType.fetchRequest()
        } catch {
            preconditionFailure()
        }
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "organization", ascending: true),
            NSSortDescriptor(key: "title", ascending: true),
        ]
        let moc = DataStore.shared.reader
        let frc = FRC(fetchRequest: fetchRequest, managedObjectContext: moc, cacheName: "NewIssueTypeCache")
        return FRCCollectionView(fetchedResultsController: frc) { [weak self] () -> UICollectionView? in
            return self?.collectionView
        }
    }()
    var fetchedResultsController: FRC<ReportType> {
        get {
            return self.fetchResultsControllerCollectionViewAdapter.fetchedResultsController
        }
    }
    @IBOutlet var collectionView: UICollectionView?
    var location = LocationAdapter()
    private func reportsLoaded(succeeded: Bool) {
        guard succeeded else {
            print("failed reports type lookup")
            return
        }
        guard let collectionView = self.collectionView else {
            return
        }
        let headerIndexPaths = collectionView.indexPathsForVisibleSupplementaryElements(ofKind: UICollectionElementKindSectionHeader)
        for indexPath in headerIndexPaths {
            guard let view = collectionView.supplementaryView(forElementKind: UICollectionElementKindSectionHeader, at: indexPath) as? NewIssueTypeOrganizationHeader else {
                continue;
            }
            do {
                if try fetchedResultsController.count(section: indexPath.section) > 0 {
                    let reportType = fetchedResultsController.object(at: IndexPath(item: 0, section: indexPath.section))
                    view.title?.text = reportType.organization
                } else {
                    view.title?.text = nil
                }
            } catch {
                view.title?.text = nil
            }
        }
    }
    private func didUpdateLocation(location: CLLocation) {
        Coordinator.shared.reportTypes(location: Point(location: location)).then(on: DispatchQueue.main) { [weak self] succeeded in
            self?.reportsLoaded(succeeded: succeeded)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString("NewIssueTypeViewController.IssueType", comment: "")
        location.didUpdateLocations = { [weak self] manager, locations in
            guard let location = locations.first else {
                return
            }
            self?.didUpdateLocation(location: location)
        }
        location.clients = [Clients.newIssueType]
        location.start()
        do {
            try fetchedResultsController.performFetch()
        } catch {
            print("fetch failed")
        }
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        guard let destination = segue.destination as? NewIssueDetailViewController else {
            return
        }
        guard let cell = sender as? NewIssueTypeCell else {
            return
        }
        guard let indexPath = collectionView?.indexPath(for: cell) else {
            return
        }
        let report = fetchedResultsController.object(at: indexPath)
        let identifier = Int(report.id)
        destination.reportTypeIdentifier = identifier
        Coordinator.shared.reportDetails(identifier: identifier)
    }
}

extension NewIssueTypeViewController : UICollectionViewDelegate {
    
}

extension NewIssueTypeViewController : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        do {
            return try fetchedResultsController.count(section: section)
        } catch {
            return 0
        }
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.cellIdentifier, for: indexPath) as? NewIssueTypeCell else {
            preconditionFailure()
        }
        let reportType = fetchedResultsController.object(at: indexPath)
        cell.title?.text = reportType.title
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard kind == UICollectionElementKindSectionHeader else {
            preconditionFailure()
        }
        guard let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "SectionHeader", for: indexPath) as? NewIssueTypeOrganizationHeader else {
            preconditionFailure()
        }
        do {
            if try fetchedResultsController.count(section: indexPath.section) > 0 {
                let reportType = fetchedResultsController.object(at: IndexPath(item: 0, section: indexPath.section))
                view.title?.text = reportType.organization
            } else {
                view.title?.text = nil
            }
        } catch {
            view.title?.text = nil
        }
        return view
    }
}
