//
//  Collar.swift
//  Collar
//
//  Created by Filip Gulan on 06/03/2020.
//  Copyright © 2020 Infinum. All rights reserved.
//

import Foundation

public enum LogType: String {
    case userProperty = "User property"
    case event = "Event"
    case screen = "Screen view"
}

public struct LogItem: CustomStringConvertible {
    public let type: LogType
    public let name: String
    public let timestamp: Date
    public let value: String?
    public let parameters: [String: Any]?

    static let dateFormatter = ISO8601DateFormatter()

    init(screenName: String, screenClass: String?) {
        self.init(type: .screen, name: screenName, value: screenClass)
    }
    
    init(event: String, timestamp: Date, parameters: [String: Any]?) {
        self.init(type: .event, name: event, timestamp: timestamp, parameters: parameters)
    }
    
    init(userProperty: String, value: String?) {
        self.init(type: .userProperty, name: userProperty, value: value)
    }
    
    init(type: LogType, name: String, timestamp: Date = Date(), value: String? = nil, parameters: [String: Any]? = nil) {
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
        lines.append("Timestamp: \(LogItem.dateFormatter.string(from: timestamp))")
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

public class AnalyticsCollectionManager {
    
    public enum Notification {
        public static var didUpdateLogs = Foundation.Notification(name: .init("AnalyticsCollectionManager.didUpdateLogs"))
    }
    
    public static let shared = AnalyticsCollectionManager()
    
    public private(set) var logs: [LogItem] = [] {
        didSet {
            NotificationCenter.default.post(AnalyticsCollectionManager.Notification.didUpdateLogs)
            if let last = logs.last {
                LogItemPopupQueue.shared.show(last)
            }
        }
    }

    public func clearLogs() {
        logs = []
    }
}

// MARK: - Logging

public extension AnalyticsCollectionManager {
    
    func track(screenName: String?, screenClass: String?) {
        guard let screenName = screenName else { return }
        DispatchQueue.main.async { [weak self] in
            self?.logs.append(.init(screenName: screenName, screenClass: screenClass))
        }
    }

    func setUserProperty(_ value: String?, forName name: String) {
        DispatchQueue.main.async { [weak self] in
            self?.logs.append(.init(userProperty: name, value: value))
        }
    }
    
    func log(event: String, timestamp: Date = Date(), parameters: [String: Any]?) {
        DispatchQueue.main.async { [weak self] in
            self?.logs.append(.init(event: event, timestamp: timestamp, parameters: parameters))
        }
    }
}

extension LogItem {
    
    var paramsJSONString: String? {
        guard
            let parameters = parameters,
            !parameters.isEmpty
        else { return nil }
        let data = try? JSONSerialization
            .data(withJSONObject: parameters, options: [.prettyPrinted, .sortedKeys])
        return data
            .flatMap { String(data: $0, encoding: .utf8) }
    }
}
