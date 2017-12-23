//
//  ReportType.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import Foundation
import CoreData
import SeeClickFix

@objc(ReportType)
public final class ReportType : NSManagedObject, ManagedObject {
    public typealias CoreDataType = ReportType
    public typealias JSONType = SeeClickFix.ReportType
    @NSManaged public var cacheIdentifier: String
    @NSManaged public var lastUpdated: Date
    @NSManaged public var title: String
    @NSManaged public var id: Int64
    @NSManaged public var organization: String?
    public var url: URL? {
        get {
            guard let primitive = primitiveValue(forKey: "url") as? String else {
                return nil
            }
            return URL(string: primitive)
        }
        set {
            if let value = newValue?.absoluteString {
                setPrimitiveValue(value, forKey: "url")
            } else {
                setPrimitiveValue(nil, forKey: "url")
            }
        }
    }
    public var potentialDuplicateIssuesURL: URL? {
        get {
            guard let primitive = primitiveValue(forKey: "potentialDuplicateIssuesURL") as? String else {
                return nil
            }
            return URL(string: primitive)
        }
        set {
            if let value = newValue?.absoluteString {
                setPrimitiveValue(value, forKey: "potentialDuplicateIssuesURL")
            } else {
                setPrimitiveValue(nil, forKey: "potentialDuplicateIssuesURL")
            }
        }
    }
    @NSManaged public var questions: Set<Question>?
    @objc(addQuestionsObject:)
    @NSManaged public func addToQuestions(_ value: Question)
    @objc(removeQuestionsObject:)
    @NSManaged public func removeFromQuestions(_ value: Question)
    @objc(addQuestions:)
    @NSManaged public func addToQuestions(_ values: Set<Question>)
    @objc(removeQuestions:)
    @NSManaged public func removeFromQuestions(_ values: Set<Question>)
    public func update(json: SeeClickFix.ReportType) {
        switch json.id {
        case let .integer(id):
            self.id = Int64(id)
        case .string:
            return
        }
        title = json.title
        self.id = Int64(id)
        organization = json.organization
        url = json.url
        potentialDuplicateIssuesURL = json.potential_duplicate_issues_url
        lastUpdated = Date()
    }
}

