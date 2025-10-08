//
//  ViewController.swift
//  Collar
//
//  Created by Filip Gulan on 04/11/2020.
//  Copyright (c) 2020 Filip Gulan. All rights reserved.
//

import UIKit
import SwiftUI
import Collar

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        setupButtons()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            AnalyticsCollectionManager.shared.log(event: "Test Event", parameters: [
                "param1": "value1",
                "param2": "value2"
            ])
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            AnalyticsCollectionManager.shared.setUserProperty("up_value", forName: "up_name")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            AnalyticsCollectionManager.shared.track(screenName: "Profile Screen", screenClass: "UIViewController")
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            AnalyticsCollectionManager.shared.log(event: "Login pressed", parameters: [
                "type": "guest",
                "target": "details",
                "source": "onboarding"
            ])
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            AnalyticsCollectionManager.shared.showLogs(from: self)
        }
    }

    func setupButtons() {
        let openSwiftUIButton = UIButton(type: .system)
        openSwiftUIButton.setTitle("Open SwiftUI View", for: .normal)
        openSwiftUIButton.addTarget(self, action: #selector(openSwiftUIView), for: .touchUpInside)
        openSwiftUIButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(openSwiftUIButton)

        let openFromVCButton = UIButton(type: .system)
        openFromVCButton.setTitle("Open from UIViewController", for: .normal)
        openFromVCButton.addTarget(self, action: #selector(openFromViewController), for: .touchUpInside)
        openFromVCButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(openFromVCButton)

        NSLayoutConstraint.activate([
            openSwiftUIButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            openSwiftUIButton.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -20),

            openFromVCButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            openFromVCButton.topAnchor.constraint(equalTo: openSwiftUIButton.bottomAnchor, constant: 20)
        ])
    }

    @objc private func openSwiftUIView() {
        let swiftUIView = CollarView()
        let hostingController = UIHostingController(rootView: swiftUIView)
        present(hostingController, animated: true)
    }

    @objc private func openFromViewController() {
        AnalyticsCollectionManager.shared.showLogs(from: self)
    }
}
