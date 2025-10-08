//
//  LogFilterView.swift
//  Pods
//
//  Created by Petar Jadek on 08.10.2025.
//  Copyright © 2025 Infinum. All rights reserved.
//

import SwiftUI

enum LogFilterType: String, CaseIterable {
    case all = "All"
    case userProperty = "User Properties"
    case event = "Events"
    case screen = "Screen Views"

    var color: Color {
        switch self {
        case .all: .orange
        case .userProperty: .teal
        case .event: .green
        case .screen: .indigo
        }
    }

    var icon: Image {
        switch self {
        case .all: Image(systemName: "list.clipboard.fill")
        case .userProperty: Image(systemName: "wrench.and.screwdriver.fill")
        case .event: Image(systemName: "hand.tap.fill")
        case .screen: Image(systemName: "iphone.app.switcher")
        }
    }

    var logType: [LogType] {
        switch self {
        case .all: [.event, .screen, .userProperty]
        case .userProperty: [.userProperty]
        case .event: [.event]
        case .screen: [.screen]
        }
    }
}

struct LogFilterView: View {

    @Binding var selectedFilterType: LogFilterType
    let filterTypes: [LogFilterType] = [.all, .event, .screen, .userProperty]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(filterTypes, id: \.self) { type in
                    filterItem(type: type)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, Constants.bottomPadding)
        }
    }

    func filterItem(type: LogFilterType) -> some View {
        Button(action: { selectedFilterType = type }) {
            HStack(alignment: .center, spacing: Constants.itemSpacing) {
                type.icon
                    .resizable()
                    .scaledToFit()
                    .frame(width: Constants.iconSize, height: Constants.iconSize)
                    .padding(Constants.iconPadding)
                    .foregroundStyle(checkIfSelected(type) ? .white : Color.primary)

                Text(type.rawValue)
                    .font(.caption)
                    .bold()
                    .foregroundStyle(checkIfSelected(type) ? .white : Color.primary)
            }
            .padding(.horizontal, Constants.horizontalPadding)
            .padding(.vertical, Constants.verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: Constants.cornerSize)
                    .fill(checkIfSelected(type) ? type.color : Color(.tertiarySystemFill))
            )
            .animation(.bouncy, value: selectedFilterType)
        }
    }

    func checkIfSelected(_ type: LogFilterType) -> Bool {
        selectedFilterType == type
    }
}


private extension LogFilterView {

    enum Constants {
        static let itemSpacing: CGFloat = 4
        static let iconSize: CGFloat = 16
        static let iconPadding: CGFloat = 4
        static let cornerSize: CGFloat = 16
        static let horizontalPadding: CGFloat = 12
        static let verticalPadding: CGFloat = 4
        static let bottomPadding: CGFloat = 8
    }
}
