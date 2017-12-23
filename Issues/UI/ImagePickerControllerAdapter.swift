//
//  ImagePickerControllerAdapter.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import AVFoundation.AVAssetExportSession
import MobileCoreServices
import Photos
import UIKit

class ImagePicker {
    private class Delegate : NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let key: String
        var result: ((Answer<URL>) -> Void)?
        init(key: String) {
            self.key = key
            super.init()
        }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
            func setImageAnswer(url: URL) {
                self.result?(Answer(key: key, value: url))
            }
            if let asset = info[UIImagePickerControllerPHAsset] as? PHAsset {
                let imageManager = PHImageManager.default()
                switch asset.mediaType {
                case .image:
                    imageManager.requestImageData(for: asset, options: nil) { data, uti, orientation, info in
                        guard let data = data else {
                            return
                        }
                        ImageCache.shared.cacheImage(data: data).then(on: CFRunLoop.main) { url in
                            setImageAnswer(url: url)
                        }
                    }
                case .video:
                    break
                default:
                    break
                }
            } else if let image = info[UIImagePickerControllerEditedImage] as? UIImage {
                ImageCache.shared.cacheImage(image: image).then(on: CFRunLoop.main) { url in
                    setImageAnswer(url: url)
                }
            } else if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
                ImageCache.shared.cacheImage(image: image).then(on: CFRunLoop.main) { url in
                    setImageAnswer(url: url)
                }
            }
            picker.dismiss(animated: true, completion: nil)
        }
    }
    private var alert: UIAlertController?
    private var picker: UIImagePickerController?
    private let delegate: Delegate
    var key: String {
        get {
            return delegate.key
        }
    }
    var present: ((UIViewController, Bool, (() -> Void)?) -> Void)?
    var result: ((Answer<URL>) -> Void)? {
        get {
            return delegate.result
        }
        set {
            delegate.result = newValue
        }
    }
    init(key: String) {
        delegate = Delegate(key: key)
    }
    func showMediaActionSheet() {
        let alert = UIAlertController(title: "P", message: "?", preferredStyle: .actionSheet)
        func addAction(title: String, handler: @escaping () -> Void) {
            alert.addAction(UIAlertAction(title: title, style: .default, handler: { _ in handler() }))
        }
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            addAction(title: NSLocalizedString("ImagePicker.TakePicture", comment: "")) {
                self.takePicture()
                self.alert = nil
            }
            addAction(title: NSLocalizedString("ImagePicker.TakeVideo", comment: "")) {
                self.takeVideo()
                self.alert = nil
            }
        }
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            if let mediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
                if mediaTypes.contains(kUTTypeImage as String) {
                    addAction(title: NSLocalizedString("ImagePicker.PhotoLibrary", comment: "")) {
                        self.photoLibrary()
                        self.alert = nil
                    }
                }
                if mediaTypes.contains(kUTTypeVideo as String) {
                    addAction(title: NSLocalizedString("ImagePicker.VideoLibrary", comment: "")) {
                        self.videoLibrary()
                        self.alert = nil
                    }
                }
            }
        }
        self.alert = alert
        present?(alert, true, nil)
    }
    private func capture(mode: UIImagePickerControllerCameraCaptureMode) {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = mode
        picker.delegate = delegate
        self.picker = picker
        present?(picker, true, nil)
    }
    private func library(mediaType: String) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.mediaTypes = [mediaType]
        picker.delegate = delegate
        self.picker = picker
        present?(picker, true, nil)
    }
    private func takePicture() {
        capture(mode: .photo)
    }
    private func takeVideo() {
        capture(mode: .video)
    }
    private func photoLibrary() {
        library(mediaType: kUTTypeImage as String)
    }
    private func videoLibrary() {
        library(mediaType: kUTTypeVideo as String)
    }
}
