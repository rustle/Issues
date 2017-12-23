//
//  DataStore.swift
//  Reports
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import Foundation
import CoreData
import SeeClickFix

extension NSManagedObjectContext : ExecutionContext {
    public func execute(_ work: @escaping () -> Void) {
        perform {
            work()
        }
    }
}

public class DataStore {
    public static let shared: DataStore = {
        do {
            return try DataStore()
        } catch {
            // We'll try to recover below by nuking the database file
        }
        do {
            try FileManager.default.removeItem(at: try url())
            return try DataStore()
        } catch {
            preconditionFailure()
        }
    }()
    private struct Constants {
        static let errorDomain = "com.DetroitBlockWorks.DataStore"
        static let storeName = "Reports.sqlite"
    }
    // Main thread only reader context
    public private(set) var reader: NSManagedObjectContext
    public func child() -> NSManagedObjectContext {
        let child = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        child.parent = reader
        return child
    }
    // Synchronous save that expects to be called from the contexts private queue (i.e. from within a perform block or on the main queue for the reader context)
    public func save(_ context: NSManagedObjectContext) throws {
        try context.save()
    }
    // Async save that also saves reader & then writer contexts
    public func save(child context: NSManagedObjectContext) -> Promise<Bool> {
        let promise = Promise<Bool>()
        if !context.hasChanges {
            promise.fulfill(true)
            return promise
        }
        do {
            try save(context)
            reader.perform {
                do {
                    try self.save(self.reader)
                    promise.fulfill(true)
                } catch let error {
                    promise.reject(error)
                }
                self.writer.perform {
                    do {
                        try self.save(self.writer)
                    } catch let error {
                        promise.reject(error)
                    }
                }
            }
        } catch let error {
            promise.reject(error)
        }
        return promise
    }
    private let managedObjectModel: NSManagedObjectModel
    private let persistentStoreCoordinator: NSPersistentStoreCoordinator
    private let writer: NSManagedObjectContext
    private static func url() throws -> URL {
        let directory = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return directory.appendingPathComponent(Constants.storeName)
    }
    private init() throws {
        guard let model = NSManagedObjectModel.mergedModel(from: nil) else {
            let userInfo = [NSLocalizedDescriptionKey : NSLocalizedString("DataStore.ManagedModelNotFound", comment: "")]
            throw NSError(domain: Constants.errorDomain, code: 0, userInfo: userInfo)
        }
        managedObjectModel = model
        persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        let url = try DataStore.url()
        try persistentStoreCoordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        // We can probably swallow this failing, hopefully
        do {
            try FileManager.default.setAttributes([FileAttributeKey.protectionKey : FileProtectionType.completeUntilFirstUserAuthentication], ofItemAtPath: url.path)
        } catch let error {
            print(error)
        }
        writer = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        writer.persistentStoreCoordinator = persistentStoreCoordinator
        reader = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        reader.parent = writer
    }
}
