//
//  Coordinator.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import Foundation
import CoreData
import SeeClickFix

extension BoundedQueue : ExecutionContext {
    public func execute(_ work: @escaping () -> Void) {
        async {
            work()
        }
    }
}

class Coordinator {
    static let shared = Coordinator()
    init() {
        _ = DataStore.shared
        _ = NetworkController.shared
    }
    private let workQueue = BoundedQueue(label: "org.DetroitBlockWorks.Coordinator.WorkQueue", count: ProcessInfo.processInfo.processorCount * 2)
}

// MARK: API Requests
extension Coordinator {
    @discardableResult
    func issues(location: SeeClickFix.Location, page: Int, count: Int) -> Promise<Bool> {
        let context = DataStore.shared.child()
        let network = NetworkController.shared
        return network.issues(location: location, page: page, count: count).then(on: workQueue, { data in
            return try Issues.decode(data: data).issues
        }).then(on: context, { issues in
            var idMap = [Int : SeeClickFix.Issue]()
            for json in issues {
                switch json.id {
                case let .integer(id):
                    idMap[id] = json
                case .string:
                    continue
                }
            }
            let fetchRequest: NSFetchRequest<Issue> = try Issue.fetchRequest(identifiers: Set(idMap.keys))
            for managedObject in try context.fetch(fetchRequest) {
                let id = Int(managedObject.id)
                if let result = idMap[id] {
                    managedObject.update(json: result)
                    idMap.removeValue(forKey: id)
                }
            }
            for result in idMap.values {
                let newManagedObject = try Issue.insert(into: context)
                newManagedObject.update(json: result)
            }
            return DataStore.shared.save(child: context)
        })
    }
    @discardableResult
    func reportTypes(location: Location) -> Promise<Bool> {
        let context = DataStore.shared.child()
        let network = NetworkController.shared
        return network.reportTypes(location: location).then(on: workQueue, { data in
            return try ReportTypes.decode(data: data).request_types
        }).then(on: context, { reportTypes in
            var idMap = [Int : SeeClickFix.ReportType]()
            for json in reportTypes {
                switch json.id {
                case let .integer(id):
                    idMap[id] = json
                case .string:
                    continue
                }
            }
            let fetchRequest: NSFetchRequest<ReportType> = try ReportType.fetchRequest(identifiers: Set(idMap.keys))
            for managedObject in try context.fetch(fetchRequest) {
                let id = Int(managedObject.id)
                if let result = idMap[id] {
                    managedObject.update(json: result)
                    idMap.removeValue(forKey: id)
                }
            }
            for result in idMap.values {
                let newManagedObject = try ReportType.insert(into: context)
                newManagedObject.update(json: result)
            }
            return DataStore.shared.save(child: context)
        })
    }
    enum ReportDetailsError : Error {
        case reportTypeFetchUnsuccessful
    }
    private func reportType(context: NSManagedObjectContext, identifier: Int) throws -> ReportType {
        let fetchRequest = try ReportType.fetchRequest(identifier: identifier)
        let fetchResults: [ReportType]
        do {
            fetchResults = try context.fetch(fetchRequest)
        } catch {
            throw ReportDetailsError.reportTypeFetchUnsuccessful
        }
        guard let reportType = fetchResults.first else {
            throw ReportDetailsError.reportTypeFetchUnsuccessful
        }
        return reportType
    }
    @discardableResult
    func reportDetails(identifier: Int) -> Promise<Bool> {
        let context = DataStore.shared.child()
        let network = NetworkController.shared
        return network.reportDetails(identifier: identifier).then(on: workQueue, { data in
            return try ReportDetails.decode(data: data).questions
        }).then(on: context, { questions in
            let reportType = try self.reportType(context: context, identifier: identifier)
            if let questions = reportType.questions {
                for question in questions {
                    context.delete(question)
                }
            }
            let newManagedObject = try Question.insert(into: context)
            newManagedObject.setPrimitiveValue(NSNumber(value: Question.Format.location.rawValue), forKey: "format")
            newManagedObject.order = -2
            reportType.addToQuestions(newManagedObject)
            newManagedObject.reportType = reportType
            for (order, question) in questions.enumerated() {
                let newManagedObject = try Question.insert(into: context)
                newManagedObject.update(json: question)
                if try newManagedObject.format() == .image {
                    newManagedObject.order = -1
                } else {
                    newManagedObject.order = Int16(order)
                }
                reportType.addToQuestions(newManagedObject)
                newManagedObject.reportType = reportType
            }
            return DataStore.shared.save(child: context)
        })
    }
    @discardableResult
    func submitReport(answers: [AnyAnswer]) -> Promise<Bool> {
        return Promise()
    }
}
