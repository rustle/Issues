//
//  FetchedResultsControllerCollectionViewAdapter.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import UIKit
import CoreData

public enum Change {
    case insert(IndexPath)
    case delete(IndexPath)
    case move(IndexPath, IndexPath)
    case update(IndexPath)
}

public class FRCCollectionView<T : NSFetchRequestResult> {
    public var willChange: ((FRCCollectionView<T>) -> Void)?
    public var didChange: ((FRCCollectionView<T>) -> Void)?
    private var changes = [Change]()
    private func insert(_ indexPath: IndexPath) {
        changes.append(Change.insert(indexPath))
    }
    private var deletes = [IndexPath]()
    private func delete(_ indexPath: IndexPath) {
        changes.append(Change.delete(indexPath))
    }
    private var moves = [(IndexPath, IndexPath)]()
    private func move(oldIndexPath: IndexPath, newIndexPath: IndexPath) {
        changes.append(Change.move(oldIndexPath, newIndexPath))
    }
    private var updates = [IndexPath]()
    private func update(_ indexPath: IndexPath) {
        changes.append(Change.update(indexPath))
    }
    public var fetchedResultsController: FRC<T>
    public init(fetchedResultsController: FRC<T>, collectionViewProvider: @escaping () -> UICollectionView?) {
        self.fetchedResultsController = fetchedResultsController
        self.fetchedResultsController.willChange = { [weak self] _ in
            if let frc = self, let willChange = frc.willChange {
                willChange(frc)
            }
        }
        self.fetchedResultsController.didMove = { [weak self] _, _, oldIndexPath, newIndexPath in
            self?.move(oldIndexPath: oldIndexPath, newIndexPath: newIndexPath)
        }
        self.fetchedResultsController.didUpdate = { [weak self] _, _, indexPath in
            self?.update(indexPath)
        }
        self.fetchedResultsController.didDelete = { [weak self] _, _, indexPath in
            self?.delete(indexPath)
        }
        self.fetchedResultsController.didInsert = { [weak self] _, _, indexPath in
            self?.insert(indexPath)
        }
        self.fetchedResultsController.didChange = { [weak self] _ in
            guard let collectionView = collectionViewProvider(), let frc = self else {
                return
            }
            collectionView.performBatchUpdates({
                // TODO: Merge changes into ranges when their types match
                for change in frc.changes {
                    switch change {
                    case .delete(let indexPath):
                        collectionView.deleteItems(at: [indexPath])
                    case .insert(let indexPath):
                        collectionView.insertItems(at: [indexPath])
                    case .move(let old, let new):
                        collectionView.moveItem(at: old, to: new)
                    case .update(let indexPath):
                        collectionView.reloadItems(at: [indexPath])
                    }
                }
            }, completion: nil)
            frc.changes = []
            if let didChange = frc.didChange {
                didChange(frc)
            }
        }
    }
}
