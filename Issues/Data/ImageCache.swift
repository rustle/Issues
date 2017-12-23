//
//  ImageCache.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import UIKit
import SeeClickFix

extension NotificationCenter {
    private class ObserverBox {
        var observer: Any?
    }
    func issues_onceObserver(name: NSNotification.Name, object: Any?, queue: OperationQueue?, block: @escaping (Notification) -> Void) {
        let box = ObserverBox()
        box.observer = addObserver(forName: name, object: object, queue: queue) { [weak self] note in
            block(note)
            if let observer = box.observer {
                self?.removeObserver(observer)
            }
        }
    }
}

extension FileHandle {
    enum FileHandleError : Error {
        case unableToReadPath
        case unknownReadError
        case unix(errorCode: Int)
    }
    static func readFile(url: URL, ioThread: IOThread) -> Promise<Data> {
        precondition(url.isFileURL)
        do {
            let promise = Promise<Data>()
            try ioThread.perform {
                guard let fileHandle = FileHandle(forReadingAtPath: url.path) else {
                    promise.reject(FileHandleError.unableToReadPath)
                    return
                }
                NotificationCenter.default
                    .issues_onceObserver(name: .NSFileHandleReadToEndOfFileCompletion, object: fileHandle, queue: nil) { note in
                        guard let data = note.userInfo?[NSFileHandleNotificationDataItem] as? Data else {
                            if let error = note.userInfo?["NSFileHandleError"] as? NSNumber {
                                promise.reject(FileHandleError.unix(errorCode: error.intValue))
                            } else {
                                promise.reject(FileHandleError.unknownReadError)
                            }
                            return
                        }
                        promise.fulfill(data)
                    }
                fileHandle.readToEndOfFileInBackgroundAndNotify()
            }
            return promise
        } catch let error {
            return Promise(error: error)
        }
    }
}

class ImageCache {
    static let shared = ImageCache()
    private let ioThread = IOThread()
    private let cache = NSCache<NSURL, UIImage>()
    enum ImageCacheError : Error {
        case unsupportedURLScheme
        case badImageData
        case urlCreationFailed
    }
    private let workQueue = BoundedQueue(label: "org.DetroitBlockWorks.ImageCache.WorkQueue", count: ProcessInfo.processInfo.processorCount * 2)
    private let imageCacheDirectory: URL?
    private init() {
        imageCacheDirectory = ImageCache.setupCacheDirectoryIfNeeded()
    }
    private static func setupCacheDirectoryIfNeeded() -> URL? {
        guard let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        let imageCacheDirectory = url.appendingPathComponent("ImageCache")
        var reachable: Bool
        do {
            reachable = try imageCacheDirectory.checkResourceIsReachable()
        } catch {
            reachable = false
        }
        if reachable {
            return imageCacheDirectory
        }
        do {
            try FileManager.default.createDirectory(at: imageCacheDirectory,
                                                    withIntermediateDirectories: false,
                                                    attributes: nil)
            return imageCacheDirectory
        } catch {
            return nil
        }
    }
    private func makeUniqueURL() throws -> URL {
        guard let cacheDirectory = imageCacheDirectory else {
            throw ImageCacheError.urlCreationFailed
        }
        // Try a few times then give up
        for _ in 0...3 {
            let uuid = UUID()
            let time = Int(CFAbsoluteTimeGetCurrent())
            let url = cacheDirectory.appendingPathComponent("\(uuid)-\(time)")
            if !FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }
        throw ImageCacheError.urlCreationFailed
    }
    private func scaleForProportionalResize(originSize: CGSize, targetSize: CGSize, onlyScaleDown: Bool, maximize: Bool) -> CGFloat {
        let sx = originSize.width
        let sy = originSize.height
        var dx = targetSize.width
        var dy = targetSize.height
        var scale: CGFloat = 1.0
        if sx != 0, sy != 0 {
            dx = dx / sx
            dy = dy / sy
            // if maximize is true, take LARGER of the scales, else smaller
            if maximize {
                scale = (dx > dy) ? dx : dy;
            } else {
                scale = (dx < dy) ? dx : dy;
            }
            if scale > 1.0, onlyScaleDown {
                scale = 1.0; // reset scale
            }
        } else {
            scale = 0.0;
        }
        return scale;
    }
    private func scaleImage(image: UIImage) -> UIImage {
        return UIImage()
    }
    func cacheImage(data: Data) -> Promise<URL> {
        do {
            let url = try makeUniqueURL()
            try data.write(to: url)
            return Promise(value: url)
        } catch let error {
            return Promise(error: error)
        }
    }
    func cacheImage(image: UIImage) -> Promise<URL> {
        let promise = Promise<URL>()
        workQueue.async {
            if let data = UIImageJPEGRepresentation(image, 0.8) {
                self.cacheImage(data: data).then() { url in
                    self.cache.setObject(image, forKey: url as NSURL)
                    promise.fulfill(url)
                }
            } else {
                promise.reject(ImageCacheError.badImageData)
            }
        }
        return promise
    }
    func image(url: URL, size: CGSize? = nil) -> Promise<(UIImage, URL)> {
        if url.isFileURL {
            if let image = cache.object(forKey: url as NSURL) {
                return Promise(value: (image, url))
            }
            return FileHandle.readFile(url: url, ioThread: ioThread)
                .then(on: workQueue) { data in
                    guard let image = UIImage(data: data) else {
                        throw ImageCacheError.badImageData
                    }
                    self.cache.setObject(image, forKey: url as NSURL)
                    return Promise(value: (image, url))
            }
        } else if url.scheme == "http" || url.scheme == "https" {
            return NetworkController.shared.dataTask(request: URLRequest(url: url))
                .then(on: workQueue) { data, response in
                    guard let image = UIImage(data: data) else {
                        throw ImageCacheError.badImageData
                    }
                    return self.cacheImage(data: data).then() { url in
                        self.cache.setObject(image, forKey: url as NSURL)
                        return Promise(value: (image, url))
                    }
            }
        }
        return Promise(error: ImageCacheError.unsupportedURLScheme)
    }
}
