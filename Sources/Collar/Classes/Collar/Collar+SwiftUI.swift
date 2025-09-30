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
