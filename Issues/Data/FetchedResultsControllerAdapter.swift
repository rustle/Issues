//
//  FetchedResultsControllerAdapter.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import Foundation
import CoreData

public struct FRC<T : NSFetchRequestResult> {
    private let fetchedResultsController: NSFetchedResultsController<T>
    private class Adapter : NSObject, NSFetchedResultsControllerDelegate {
        fileprivate var willChange: ((NSFetchedResultsController<T>) -> Void)?
        fileprivate var didDelete: ((NSFetchedResultsController<T>, T, IndexPath) -> Void)?
        fileprivate var didInsert: ((NSFetchedResultsController<T>, T, IndexPath) -> Void)?
        fileprivate var didMove: ((NSFetchedResultsController<T>, T, IndexPath, IndexPath) -> Void)?
        fileprivate var didUpdate: ((NSFetchedResultsController<T>, T, IndexPath) -> Void)?
        fileprivate var didChange: ((NSFetchedResultsController<T>) -> Void)?
        func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            guard let controller = controller as? NSFetchedResultsController<T> else {
                return
            }
            willChange?(controller)
        }
        func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
            guard let controller = controller as? NSFetchedResultsController<T> else {
                return
            }
            didChange?(controller)
        }
        func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
            guard let issue = anObject as? T else {
                return
            }
            guard let controller = controller as? NSFetchedResultsController<T> else {
                return
            }
            switch type {
            case .delete:
                didDelete?(controller, issue, indexPath!)
            case .insert:
                didInsert?(controller, issue, newIndexPath!)
            case .move:
                didMove?(controller, issue, indexPath!, newIndexPath!)
            case .update:
                didUpdate?(controller, issue, indexPath!)
            }
        }
        fileprivate override init() {
        }
    }
    private let adapter = Adapter()
    public var willChange: ((NSFetchedResultsController<T>) -> Void)? {
        get {
            return adapter.willChange
        }
        set {
            adapter.willChange = newValue
        }
    }
    public var didDelete: ((NSFetchedResultsController<T>, T, IndexPath) -> Void)? {
        get {
            return adapter.didDelete
        }
        set {
            adapter.didDelete = newValue
        }
    }
    public var didInsert: ((NSFetchedResultsController<T>, T, IndexPath) -> Void)? {
        get {
            return adapter.didInsert
        }
        set {
            adapter.didInsert = newValue
        }
    }
    public var didMove: ((NSFetchedResultsController<T>, T, IndexPath, IndexPath) -> Void)? {
        get {
            return adapter.didMove
        }
        set {
            adapter.didMove = newValue
        }
    }
    public var didUpdate: ((NSFetchedResultsController<T>, T, IndexPath) -> Void)? {
        get {
            return adapter.didUpdate
        }
        set {
            adapter.didUpdate = newValue
        }
    }
    public var didChange: ((NSFetchedResultsController<T>) -> Void)? {
        get {
            return adapter.didChange
        }
        set {
            adapter.didChange = newValue
        }
    }
    public enum FRCError : Error {
        case nilSections
        case outOfBounds
    }
    public func sections() throws -> [NSFetchedResultsSectionInfo] {
        guard let sections = fetchedResultsController.sections else {
            throw FRCError.nilSections
        }
        return sections
    }
    public func count(section: Int) throws -> Int {
        let sections = try self.sections()
        guard section < sections.count else {
            throw FRCError.outOfBounds
        }
        let count = sections[section].numberOfObjects
        return count
    }
    /*
     Deletes the cached section information with the given name.
     If name is nil, then all caches are deleted.
     */
    static func deleteCache(withName name: String?) {
        NSFetchedResultsController<T>.deleteCache(withName: name)
    }
    /*
     Returns the results of the fetch.
     Returns nil if the performFetch: hasn't been called.
     */
    public var fetchedObjects: [T]? {
        get {
            return fetchedResultsController.fetchedObjects
        }
    }
    /*
     Returns the fetched object at a given indexPath.
     */
    public func object(at indexPath: IndexPath) -> T {
        return fetchedResultsController.object(at: indexPath)
    }
    /*
     */
    public struct FetchedObjectIterator : IteratorProtocol {
        private let frc: FRC
        private lazy var indexPath: IndexPath? = {
            do {
                guard try frc.sections().count > 0 else {
                    return nil
                }
                guard try frc.count(section: 0) > 0 else {
                    return nil
                }
                return IndexPath(item: 0, section: 0)
            } catch {
                return nil
            }
        }()
        fileprivate init(_ frc: FRC) {
            self.frc = frc
        }
        public mutating func next() -> (IndexPath, T)? {
            guard var indexPath = indexPath else {
                return nil
            }
            guard let count = try? frc.count(section: indexPath.section), count > 0 else {
                return nil
            }
            if indexPath.item < count - 1 {
                indexPath.item += 1
                self.indexPath = indexPath
                return (indexPath, frc.object(at: indexPath))
            }
            return nil
        }
    }
    /*
     */
    public func iterator() -> FetchedObjectIterator {
        return FetchedObjectIterator(self)
    }
    /*
     Returns the indexPath of a given object.
     */
    public func indexPath(forObject object: T) -> IndexPath? {
        return fetchedResultsController.indexPath(forObject: object)
    }
    public init(fetchRequest: NSFetchRequest<T>, managedObjectContext: NSManagedObjectContext, cacheName: String) {
        fetchedResultsController = NSFetchedResultsController<T>(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: cacheName)
        fetchedResultsController.delegate = adapter
    }
    public func performFetch() throws {
        try fetchedResultsController.performFetch()
    }
}
