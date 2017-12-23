//
//  NewIssueCell.swift
//
//  Copyright © 2017 Detroit Block Works. All rights reserved.
//

import UIKit
import SeeClickFix
import MapKit
import Contacts

class NewIssueCell : UICollectionViewCell {
    static var nibName: String {
        return String(describing: self)
    }
    func collectionView() -> UICollectionView? {
        var collectionView: UICollectionView?
        var view: UIView? = superview
        while view != nil {
            if view is UICollectionView {
                collectionView = (view as! UICollectionView)
                break
            }
            view = view?.superview
        }
        return collectionView
    }
    func willDisplay() {
        
    }
}
