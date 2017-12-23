//
//  Question.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import Foundation
import CoreData
import SeeClickFix

@objc(Question)
public final class Question : NSManagedObject, ManagedObject {
    public typealias CoreDataType = Question
    public typealias JSONType = SeeClickFix.ReportDetails.Question
    public enum Format : Int {
        case location
        case datepicker
        case picker
        case image
        case input
        case textarea
        case label
    }
    public enum QuestionError : Error {
        case invalidFormat
    }
    @NSManaged public var order: Int16
    @NSManaged public var key: String?
    @NSManaged public var `private`: Bool
    @NSManaged public var required: Bool
    @NSManaged public var text: String?
    public func format() throws -> Format {
        guard let primitiveValue = primitiveValue(forKey: "format") as? NSNumber else {
            throw QuestionError.invalidFormat
        }
        guard let value = Format(rawValue: primitiveValue.intValue) else {
            throw QuestionError.invalidFormat
        }
        return value
    }
    public func set(format: ReportDetails.Question.QuestionType) {
        let value: NSNumber
        switch format {
        case .datetime:
            value = NSNumber(value: Format.datepicker.rawValue)
        case .file:
            value = NSNumber(value: Format.image.rawValue)
        case .note:
            value = NSNumber(value: Format.label.rawValue)
        case .multivaluelist:
            fallthrough
        case .select:
            value = NSNumber(value: Format.picker.rawValue)
        case .text:
            value = NSNumber(value: Format.input.rawValue)
        case .textarea:
            value = NSNumber(value: Format.textarea.rawValue)
        }
        setPrimitiveValue(value, forKey: "format")
    }
    @NSManaged public var reportType: ReportType?
    public func sortedValues() -> [QuestionSelectValue] {
        guard let values = selectValues else {
            return []
        }
        return values.sorted() { left, right in
            return left > right
        }
    }
    @NSManaged public var selectValues: Set<QuestionSelectValue>?
    @objc(addSelectValuesObject:)
    @NSManaged public func addToSelectValues(_ value: QuestionSelectValue)
    @objc(removeSelectValuesObject:)
    @NSManaged public func removeFromSelectValues(_ value: QuestionSelectValue)
    @objc(addSelectValues:)
    @NSManaged public func addToSelectValues(_ values: Set<QuestionSelectValue>)
    @objc(removeSelectValues:)
    @NSManaged public func removeFromSelectValues(_ values:       Set<QuestionSelectValue>)
    public func update(json: SeeClickFix.ReportDetails.Question) {
        key = json.primary_key
        text = json.question
        `private` = json.answer_kept_private
        required = json.response_required
        set(format: json.question_type)
        do {
            if let selectValues = json.select_values, let context = self.managedObjectContext {
                for selectValue in selectValues {
                    let newManagedObject = try QuestionSelectValue.insert(into: context)
                    newManagedObject.update(json: selectValue)
                    newManagedObject.question = self
                    addToSelectValues(newManagedObject)
                }
            }
        } catch let error {
            print(error)
            preconditionFailure()
        }
    }
}
