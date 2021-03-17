//
//  ViewController.swift
//  Collar
//
//  Created by Filip Gulan on 04/11/2020.
//  Copyright (c) 2020 Filip Gulan. All rights reserved.
//

import UIKit
import Collar

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        LogItemPopupQueue.shared.enabled = true
        LogItemPopupQueue.shared.showOnView = { UIApplication.shared.keyWindow }
        
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            AnalyticsCollectionManager.shared.showLogs(from: self)
        }
    }
}
