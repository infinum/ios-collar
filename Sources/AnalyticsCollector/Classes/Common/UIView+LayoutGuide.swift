//
//  UIView+LayoutGuide.swift
//  Pods
//
//  Created by Filip Gulan on 11/04/2020.
//

import UIKit

extension UIView {
    
    var saferAreaLayoutGuide: UILayoutGuide {
        if #available(iOS 11.0, *) {
            return safeAreaLayoutGuide
        } else {
            return layoutMarginsGuide
        }
    }
}
