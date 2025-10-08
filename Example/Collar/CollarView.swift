//
//  CollarView.swift
//  Collar
//
//  Created by Petar Jadek on 08.10.2025.
//  Copyright (c) 2020 Petar Jadek. All rights reserved.
//

import SwiftUI
import Collar

struct CollarView: View {

    private let analyticsCollectionManager = AnalyticsCollectionManager.shared
    @State private var isPresented = false

    var body: some View {
        Button(action: { isPresented = true }) {
            Text("Open Logs")
        }
        .collarLogSheet(isPresented: $isPresented)
    }
}
