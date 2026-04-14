//
//  LogListView.swift
//  Pods
//
//  Created by Petar Jadek on 30.09.2025.
//  Copyright © 2025 Infinum. All rights reserved.
//

import SwiftUI

struct LogListView: View {

    @Environment(\.dismiss) private var dismiss

    private let notificationName = AnalyticsCollectionManager.Notification.didUpdateLogs
    private let analyticsManager = AnalyticsCollectionManager.shared

    @State private var items: [LogItem] = []
    @State private var searchText = ""
    @State private var showFilters = false
    @State private var selectedFilterType: LogFilterType = .all

    var filteredItems: [LogItem] {
        items.filter { item in
            var matchesSearch: Bool = if searchText.isEmpty {
                true
            } else {
                item.name.localizedCaseInsensitiveContains(searchText) ||
                (item.subtitleDisplay ?? "").localizedCaseInsensitiveContains(searchText)
            }
            if searchText.isEmpty {
                matchesSearch = true
            } else {
                matchesSearch =
                item.name.localizedCaseInsensitiveContains(searchText) ||
                (item.subtitleDisplay ?? "").localizedCaseInsensitiveContains(searchText)
            }

            let matchesFilter: Bool = if selectedFilterType == .all {
                true
            } else {
                selectedFilterType.logType.contains(item.type)
            }

            return matchesSearch && matchesFilter
        }
    }
    var body: some View {
        navigationView {
            ScrollView {
                listView
            }
            .onReceive(NotificationCenter.default.publisher(for: notificationName)) { _ in updateLogs() }
            .onAppear(perform: updateLogs)
        }
    }

    private var listView: some View {
        LazyVStack(alignment: .leading, spacing: .zero) {
            LogFilterView(selectedFilterType: $selectedFilterType)

            if filteredItems.isEmpty && searchText.isEmpty {
                messageView(Constants.logsEmptyMessage)
            } else if filteredItems.isEmpty && !searchText.isEmpty {
                messageView(Constants.logsNotFound + "'" + searchText + "'")
            } else {
                Text(String(format: Constants.displayingLogs, filteredItems.count, items.count))
                    .font(.caption)
                    .padding()
                    .padding(.bottom)
                circleView(hasTopLine: false, hasBottomLine: true)
                itemList
                circleView(hasTopLine: true, hasBottomLine: false)
            }
        }
        .animation(.smooth, value: selectedFilterType)
    }

    private func messageView(_ message: String) -> some View {
        VStack(alignment: .center) {
            Text(message)
                .font(.headline)
                .bold()
                .lineLimit(nil)
                .padding(.top, Constants.messagePadding)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }

    private var itemList: some View {
        ForEach(filteredItems) { log in
            LogItemView(item: log, searchText: $searchText)
        }
        .animation(.bouncy, value: filteredItems.count)
    }

    private func circleView(hasTopLine: Bool, hasBottomLine: Bool) -> some View {
        HStack(alignment: .top, spacing: .zero) {
            VStack(alignment: .center, spacing: .zero) {
                if hasTopLine {
                    rectangleLine
                }
                Circle()
                    .frame(width: Constants.circleSize, height: Constants.circleSize)
                    .foregroundStyle(.tertiary)
                if hasBottomLine {
                    rectangleLine
                }
            }
            .frame(width: Constants.lineViewWidth)
            Spacer(minLength: .zero)
        }
        .padding(.horizontal)
    }

    private var rectangleLine: some View {
        Rectangle()
            .foregroundStyle(.tertiary)
            .frame(width: Constants.timelineSize)
    }

    private func updateLogs() {
        items = analyticsManager.logs.sorted(by: { $0.timestamp > $1.timestamp })
    }

    private func navigationView<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        NavigationView {
            content()
                .navigationBarTitle(Constants.screenTitle, displayMode: .inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(role: .destructive) {
                                analyticsManager.clearLogs()
                            } label: {
                                Label(Constants.clearLogs, systemImage: "trash.fill")
                            }
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .foregroundStyle(Color.primary)
                        }
                    }

                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .foregroundStyle(Color.primary)
                        }
                    }
                }
                .searchable(text: $searchText, prompt: Constants.searchPlaceholder)
        }
    }
}

private extension LogListView {

    enum Constants {
        static let screenTitle = "Collar Analytic Logs"
        static let searchPlaceholder = "Filter Logs"
        static let clearLogs = "Clear Logs"
        static let logsEmptyMessage = "Logs are empty."
        static let logsNotFound = "No results for: "
        static let displayingLogs: String = "Logs in category: %d, Total number of logs: %d"

        static let iconSize: CGFloat = 24
        static let iconPadding: CGFloat = 8
        static let timelineSize: CGFloat = 2
        static let lineViewWidth: CGFloat = 40
        static let circleSize: CGFloat = 8
        static let messagePadding: CGFloat = 240
    }
}
