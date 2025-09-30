//
//  Collar+UI.swift
//  Collar
//
//  Created by Filip Gulan on 06/03/2020.
//  Copyright © 2020 Infinum. All rights reserved.
//

import UIKit
import SwiftUI

// MARK: - UI

public extension AnalyticsCollectionManager {
    
    @discardableResult
    func showLogs(from viewController: UIViewController) -> UINavigationController {
        let logViewController = LogListViewController()

        let navigationController = UINavigationController(rootViewController: logViewController)
        viewController.present(navigationController, animated: true)
        return navigationController
    }

    func showCollarLogs(from viewController: UIViewController) {
        let hostingController = UIHostingController(rootView: LogListView())
        hostingController.modalPresentationStyle = .formSheet
        viewController.present(hostingController, animated: true)
    }
}
