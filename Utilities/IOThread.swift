//
//  IOThread.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import Foundation
import SeeClickFix

public class IOThread {
    fileprivate class Target : NSObject {
        fileprivate var ioRunLoop: CFRunLoop?
        private let semaphore: DispatchSemaphore
        fileprivate init(semaphore: DispatchSemaphore) {
            self.semaphore = semaphore
            super.init()
        }
        @objc
        fileprivate func entryPoint() {
            ioRunLoop = CFRunLoopGetCurrent()
            semaphore.signal()
            _ = autoreleasepool {
                Timer.scheduledTimer(timeInterval: 3600*24*365*100, target: self, selector: #selector(noap), userInfo: nil, repeats: true)
                while true {
                    _ = autoreleasepool {
                        CFRunLoopRunInMode(CFRunLoopMode.defaultMode, 10, true);
                    }
                }
            }
        }
    }
    private let target: Target
    private let semaphore = DispatchSemaphore(value: 0)
    private let ioThread: Thread
    public enum IOThreadError : Error {
        case invalid
    }
    private func ioRunLoop() throws -> CFRunLoop {
        guard let runLoop = target.ioRunLoop else {
            throw IOThreadError.invalid
        }
        return runLoop
    }
    @objc
    private func noap() { }
    public init(name: String = "IOThread") {
        target = Target(semaphore: self.semaphore)
        ioThread = Thread(target: target, selector: #selector(Target.entryPoint), object: nil)
        ioThread.name = "IOThread"
        ioThread.start()
        semaphore.wait()
    }
    public func perform(_ block: @escaping () -> Void) throws {
        try ioRunLoop().perform {
            block()
        }
    }
}

extension IOThread : ExecutionContext {
    public func execute(_ work: @escaping () -> Void) {
        do {
            try self.perform {
                work()
            }
        } catch {
            
        }
    }
}
