//
//  Issue.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import Foundation
import CoreData
import SeeClickFix

@objc(Issue)
public final class Issue : NSManagedObject, ManagedObject {
    public typealias JSONType = SeeClickFix.Issue
    @NSManaged public var address: String?
    @NSManaged public var desqription: String?
    @NSManaged public var id: Int64
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var rating: Int16
    @NSManaged public var status: String?
    @NSManaged public var summary: String?
    public func update(json: SeeClickFix.Issue) {
        switch json.id {
        case let .integer(id):
            self.id = Int64(id)
        case .string:
            return
        }
        address = json.address
        desqription = json.description
        self.id = Int64(id)
        // { 0.0, 0.0 } is a valid lat, but as far as I know SeeClickFix is US only
        // So it'll do as a default
        if let lat = json.latitude {
            latitude = lat
        } else {
            latitude = 0.0
        }
        if let long = json.longitude {
            longitude = long
        } else {
            longitude = 0.0
        }
        rating = Int16(json.rating)
        status = json.status
        summary = json.summary
    }
}
