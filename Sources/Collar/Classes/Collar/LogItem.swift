//
//  LogItem.swift
//  Collar
//
//  Created by Petar Jadek on 21.10.2025.
//  Copyright © 2025 Infinum. All rights reserved.
//

import Foundation

public enum LogType: String, Sendable {
    case userProperty = "User property"
    case event = "Event"
    case screen = "Screen view"
}

public struct LogItem: CustomStringConvertible, Identifiable, Sendable {
    public let id = UUID()
    public let type: LogType
    public let name: String
    public let timestamp: Date
    public let value: String?
    public let parameters: [String: LoggerJsonValue]?

    init(screenName: String, screenClass: String?) {
        self.init(type: .screen, name: screenName, value: screenClass)
    }

    init(event: String, timestamp: Date, parameters: [String: LoggerJsonValue]?) {
        self.init(type: .event, name: event, timestamp: timestamp, parameters: parameters)
    }

    init(userProperty: String, value: String?) {
        self.init(type: .userProperty, name: userProperty, value: value)
    }

    init(type: LogType, name: String, timestamp: Date = Date(), value: String? = nil, parameters: [String: LoggerJsonValue]? = nil) {
        self.type = type
        self.name = name
        self.timestamp = timestamp
        self.value = value
        self.parameters = parameters
    }

    public var description: String {
        var lines: [String] = []
        lines.append("Type: \(type.rawValue)")
        lines.append("Name: \(name)")
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        lines.append("Timestamp: \(formatter.string(from: timestamp))")
        if let value = value {
            switch type {
            case .screen:
                lines.append("Screen class: \(value)")
            default:
                lines.append("Value: \(value)")
            }
        }
        if let params = paramsJSONString {
            lines.append("Parameters: \(params)")
        }
        return lines.joined(separator: "\n")
    }
}

extension LogItem {

    var paramsJSONString: String? {
        guard
            let parameters = parameters,
            !parameters.isEmpty
        else { return nil }
        let jsonObject = parameters.mapValues { $0.jsonCompatible }
        let data = try? JSONSerialization
            .data(withJSONObject: jsonObject, options: [.prettyPrinted, .sortedKeys])
        return data
            .flatMap { String(data: $0, encoding: .utf8) }
    }

    var subtitleDisplay: String? {
        switch type {
        case .event:
            return paramsJSONString
        case .userProperty, .screen:
            return value
        }
    }

    var pasteboardString: String {
        let parameters = "Parameters: " + (subtitleDisplay ?? "")
        let timestamp = "Timestamp: " + timestamp.description
        return type.rawValue + ": " + name + "\n" + timestamp + "\n" + parameters
    }
}
