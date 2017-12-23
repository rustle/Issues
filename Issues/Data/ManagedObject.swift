//
//  ManagedObject.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import Foundation
import CoreData
import SeeClickFix

public protocol ManagedObject : NSFetchRequestResult {
    associatedtype JSONType : Codable
    static func fetchRequest(identifiers: Set<Int>) throws -> NSFetchRequest<Self>
    static func fetchRequest() throws -> NSFetchRequest<Self>
    static func insert(into context: NSManagedObjectContext) throws -> Self
    static func entity() -> NSEntityDescription
    static func entityName() throws -> String
    func update(json: JSONType)
}

public enum ManagedObjectError : Error {
    case uninitializedEntity
}

public extension ManagedObject {
    static func fetchRequest(identifiers: Set<Int>) throws -> NSFetchRequest<Self> {
        let request = NSFetchRequest<Self>(entityName: try entityName())
        request.predicate = NSPredicate(format: "id in %@", identifiers)
        return request
    }
    static func fetchRequest(identifier: Int) throws -> NSFetchRequest<Self> {
        let request = NSFetchRequest<Self>(entityName: try entityName())
        request.predicate = NSPredicate(format: "id == %@", NSNumber(value: identifier))
        return request
    }
    static func fetchRequest() throws -> NSFetchRequest<Self> {
        return NSFetchRequest<Self>(entityName: try entityName())
    }
    static func insert(into context: NSManagedObjectContext) throws -> Self {
        return NSEntityDescription.insertNewObject(forEntityName: try entityName(), into: context) as! Self
    }
    static func entityName() throws -> String {
        guard let name = Self.entity().name else {
            throw ManagedObjectError.uninitializedEntity
        }
        return name
    }
}
