//
//  Collar+SwiftUI.swift
//  Pods
//
//  Created by Petar Jadek on 30.09.2025..
//  Copyright © 2025 Infinum. All rights reserved.
//

import SwiftUI

public extension View {

    func collarLogSheet(isPresented: Binding<Bool>) -> some View {
        self.sheet(isPresented: isPresented) { LogListView() }
    }
}

extension LogType {

    var color: Color {
        switch self {
        case .userProperty: .teal
        case .event: .green
        case .screen: .indigo
        }
    }

    var icon: Image {
        switch self {
        case .userProperty: Image(systemName: "wrench.and.screwdriver.fill")
        case .event: Image(systemName: "hand.tap.fill")
        case .screen: Image(systemName: "iphone.app.switcher")
        }
    }
}
