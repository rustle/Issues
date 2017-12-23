//
//  BoundedQueue.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import Foundation

public class BoundedQueue {
    private let group = DispatchGroup()
    private let semaphore: DispatchSemaphore
    private let workQueue: DispatchQueue
    private let syncQueue: DispatchQueue
    public init(label: String, count: Int) {
        workQueue = DispatchQueue(label: label)
        syncQueue = DispatchQueue(label: "\(label).sync", qos: .default, attributes: [], autoreleaseFrequency: .workItem, target: nil)
        semaphore = DispatchSemaphore(value: count)
    }
    public func async(_ block: @escaping () -> Void) {
        group.enter()
        syncQueue.async {
            self.semaphore.wait()
            self.workQueue.async {
                block()
                self.semaphore.signal()
                self.group.leave()
            }
        }
    }
}
