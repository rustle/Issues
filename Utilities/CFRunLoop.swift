//
//  CFRunLoop.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import Foundation
import SeeClickFix

public extension CFRunLoop {
    public static var main: CFRunLoop {
        get {
            return CFRunLoopGetMain()
        }
    }
    public func perform(mode: CFRunLoopMode = .defaultMode, block: @escaping () -> Void) {
        CFRunLoopPerformBlock(self, mode.rawValue, block)
    }
}

extension CFRunLoop : ExecutionContext {
    public func execute(_ work: @escaping () -> Void) {
        self.perform {
            work()
        }
    }
}
