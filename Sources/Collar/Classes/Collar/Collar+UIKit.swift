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

    /// Presents the logs UI from a view controller.
    /// - Parameter viewController: The view controller to present from
    /// - Note: Must be called on the main thread.
    @MainActor
    func showLogs(from viewController: UIViewController) {
        let hostingController = UIHostingController(rootView: LogListView())
        hostingController.modalPresentationStyle = .formSheet
        viewController.present(hostingController, animated: true)
    }
}
