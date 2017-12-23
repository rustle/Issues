//
//  QuestionSelectValue.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import Foundation
import CoreData
import SeeClickFix



@objc(QuestionSelectValue)
public final class QuestionSelectValue: NSManagedObject, ManagedObject {
    public typealias CoreDataType = QuestionSelectValue
    public typealias JSONType = ReportDetails.Question.SelectValue
    @NSManaged public var order: Int16
    @NSManaged public var key: String?
    @NSManaged public var name: String?
    @NSManaged public var question: Question?
    public func update(json: ReportDetails.Question.SelectValue) {
        key = json.key
        name = json.name
    }
}

extension QuestionSelectValue {
    static func == (left: QuestionSelectValue, right: QuestionSelectValue) -> Bool {
        return left.order == right.order
    }
    static func != (left: QuestionSelectValue, right: QuestionSelectValue) -> Bool {
        return left.order != right.order
    }
    static func > (left: QuestionSelectValue, right: QuestionSelectValue) -> Bool {
        return left.order > right.order
    }
    static func < (left: QuestionSelectValue, right: QuestionSelectValue) -> Bool {
        return left.order < right.order
    }
}
