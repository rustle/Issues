//
//  NewIssueImageViewCell.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import UIKit

class NewIssueCaptureImageViewCell : NewIssueCell {
    var capture: (() -> Void)?
    @IBOutlet var addImageButton: UIButton?
    @IBOutlet var imageView: UIImageView?
    @IBAction func addImage(sender: Any?) {
        if let capture = capture {
            capture()
        }
    }
}

protocol NewIssueDisplayImageViewCellDelegate : class {
    func removeMedia()
}

class NewIssueDisplayImageViewCell : NewIssueCell {
    weak var delegate: NewIssueDisplayImageViewCellDelegate?
    var url: URL? {
        didSet {
            guard let url = url else {
                return
            }
            print("set url \(url)")
            ImageCache.shared.image(url: url, size: self.bounds.size).then(on: CFRunLoop.main) { [weak self] image, _ in
                print("set image \(image)")
                self?.imageView?.image = image
            }
        }
    }
    @IBOutlet var imageView: UIImageView?
    @IBAction func removeImage(sender: Any?) {
        delegate?.removeMedia()
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.borderColor = UIColor.black.cgColor
        layer.borderWidth = Metrics.NewIssueDisplayImageViewCell.borderWidth
        layer.cornerRadius = Metrics.NewIssueDisplayImageViewCell.cornerRadius
    }
}
