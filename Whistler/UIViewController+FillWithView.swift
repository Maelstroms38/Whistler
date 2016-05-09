//
//  UIViewController+FillWithView.swift
//  GoodDeed
//
//  Created by Michael Stromer on 3/29/16.
//  Copyright © 2016 Michael Stromer. All rights reserved.
//

import Foundation
import UIKit

extension UIViewController {
    func fillWithView(subview: UIView) {
     subview.translatesAutoresizingMaskIntoConstraints = false
     view.addSubview(subview)
        
        let viewConstraints: [NSLayoutConstraint] = [
            subview.topAnchor.constraintEqualToAnchor(topLayoutGuide.bottomAnchor),
            subview.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor),
            subview.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor),
            subview.bottomAnchor.constraintEqualToAnchor(bottomLayoutGuide.topAnchor)
        ]
        NSLayoutConstraint.activateConstraints(viewConstraints)
    }
}