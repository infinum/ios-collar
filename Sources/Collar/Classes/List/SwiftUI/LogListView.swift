//
//  LogListView.swift
//  Pods
//
//  Created by Petar Jadek on 30.09.2025.
//  Copyright © 2025 Infinum. All rights reserved.
//

import SwiftUI

struct LogListView: View {

    private let notificationName = AnalyticsCollectionManager.Notification.didUpdateLogs.name
    private let analyticsManager = AnalyticsCollectionManager.shared

    @State private var items: [LogItem] = []
    @State private var searchText = ""

    var filteredItems: [LogItem] {
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        navigationView {
            List(filteredItems) { log in
                VStack(alignment: .leading) {
                    Text(log.name)
                        .font(.body)
                    Text(log.timestamp.description)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: notificationName)) { _ in
                updateLogs()
            }
            .onAppear(perform: updateLogs)
        }
    }

    private func updateLogs() {
        items = analyticsManager.logs.sorted(by: { $0.timestamp > $1.timestamp })
    }

    private func navigationView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        Group {
            if #available(iOS 16.0, *) {
                NavigationStack {
                    content()
                        .navigationTitle(Constants.screenTitle)
                        .searchable(text: $searchText, prompt: Constants.searchPlaceholder)
                }
            } else {
                NavigationView {
                    content()
                        .navigationTitle(Constants.screenTitle)
                }
            }
        }
    }
}

private extension LogListView {

    enum Constants {
        static let screenTitle = "Logs"
        static let searchPlaceholder = "Filter Logs"
    }
}
