//
//  UITableView+Reuse.swift
//  AnalyticsCollector
//
//  Created by Filip Gulan on 06/03/2020.
//  Copyright © 2020 Infinum. All rights reserved.
//

import UIKit

extension UITableView {

    // MARK: Dequeue

    func dequeueReusableCell<T: UITableViewCell>(ofType type: T.Type, withReuseIdentifier identifier: String? = nil, for indexPath: IndexPath) -> T {
        let identifier = identifier ?? String(describing: type)
        return dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! T
    }

    // MARK: Register cell

    func registerNib<T: UITableViewCell>(cellOfType cellType: T.Type, withReuseIdentifier identifier: String? = nil) {
        let cellName = String(describing: T.self)
        let identifier = identifier ?? cellName
        let nib = UINib(nibName: cellName, bundle: .framework)
        register(nib, forCellReuseIdentifier: identifier)
    }

}
