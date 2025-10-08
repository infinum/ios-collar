//
//  LogItemView.swift
//  Pods
//
//  Created by Petar Jadek on 08.10.2025.
//  Copyright © 2025 Infinum. All rights reserved.
//

import SwiftUI

struct LogItemView: View {

    let item: LogItem
    @Binding var searchText: String

    private let analyticsManager = AnalyticsCollectionManager.shared

    var body: some View {
        HStack(alignment: .center, spacing: Constants.itemSpacing) {
            imageStep

            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                title
                if let logValue = item.subtitleDisplay {
                    parameterField(parameter: logValue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, Constants.textBottomPadding)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .contentShape(Rectangle())
    }

    var imageStep: some View {
        VStack(alignment: .center, spacing: .zero) {
            item.type.icon
                .resizable()
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .padding(Constants.iconPadding)
                .foregroundStyle(.white)
                .background(Circle().foregroundStyle(item.type.color))

            Rectangle()
                .foregroundStyle(.tertiary)
                .frame(width: Constants.timelineSize)
        }
    }

    var title: some View {
        HStack(alignment: .top, spacing: .zero) {
            VStack(alignment: .leading, spacing: Constants.textSpacing) {
                Text(item.timestamp.formatted(date: .numeric, time: .standard))
                    .font(.caption)
                    .foregroundColor(Color.secondary)

                Text(highlightedString(item.name, search: searchText))
                    .font(.body)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
            }

            Spacer(minLength: .zero)
            optionsMenu
        }
    }

    func parameterField(parameter: String) -> some View {
        Text(highlightedString(parameter, search: searchText))
            .font(.system(size: Constants.textSize, weight: .regular, design: .monospaced))
            .foregroundStyle(Color.secondary)
            .lineLimit(nil)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Constants.valuePadding)
            .background(
                RoundedRectangle(cornerRadius: Constants.cornerSize)
                    .foregroundStyle(Color(.tertiarySystemFill))
            )
            .padding(.top, Constants.valuePadding)
    }

    var optionsMenu: some View {
        Menu {
            Button(action: { UIPasteboard.general.string = item.pasteboardString }) {
                Label(Constants.copyAction, systemImage: "document.on.document.fill")
            }

            Button(role: .destructive, action: { analyticsManager.clearLog(item) }) {
                Label(Constants.removeAction, systemImage: "trash.fill")
            }
        } label: {
            Image(systemName: "ellipsis.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: Constants.iconSize, height: Constants.iconSize)
                .foregroundStyle(Color.primary, Color(.tertiarySystemFill))
        }
    }

    func highlightedString(_ text: String, search: String, highlightColor: UIColor = .yellow) -> AttributedString {
        var attributed = AttributedString(text)
        guard !search.isEmpty else { return attributed }

        let lowercasedText = text.lowercased()
        let lowercasedSearch = search.lowercased()

        var position = lowercasedText.startIndex
        while let range = lowercasedText[position...].range(of: lowercasedSearch) {
            let nsRange = NSRange(range, in: text)
            if let swiftRange = Range(nsRange, in: attributed) {
                attributed[swiftRange].backgroundColor = highlightColor.withAlphaComponent(Constants.highlightOpacity)
                attributed[swiftRange].foregroundColor = .black
            }
            position = range.upperBound
        }

        return attributed
    }
}

private extension LogItemView {

    enum Constants {
        static let removeAction = "Delete"
        static let copyAction = "Copy"


        static let iconSize: CGFloat = 24
        static let iconPadding: CGFloat = 8
        static let itemSpacing: CGFloat = 16
        static let textSpacing: CGFloat = 4
        static let textBottomPadding: CGFloat = 36
        static let timelineSize: CGFloat = 2
        static let cornerSize: CGFloat = 12
        static let valuePadding: CGFloat = 8
        static let textSize: CGFloat = 13
        static let highlightOpacity: Double = 0.8
    }
}
