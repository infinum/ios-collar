//
//  AnalyticsCollector.swift
//  AnalyticsCollector
//
//  Created by Filip Gulan on 06/03/2020.
//  Copyright © 2020 Infinum. All rights reserved.
//

import Foundation

public enum LogType {
    case userProperty, event, screen
}

public struct LogItem {
    public let type: LogType
    public let name: String
    public let timestamp: Date
    public let value: String?
    public let parameters: [String: Any]?
    
    init(screenName: String, screenClass: String?) {
        self.init(type: .screen, name: screenName, value: screenClass)
    }
    
    init(event: String, parameters: [String: Any]?) {
        self.init(type: .event, name: event, parameters: parameters)
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
    
    func log(event: String, parameters: [String: Any]?) {
        DispatchQueue.main.async { [weak self] in
            self?.logs.append(.init(event: event, parameters: parameters))
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
            .data(withJSONObject: parameters, options: .prettyPrinted)
        return data
            .flatMap { String(data: $0, encoding: .utf8) }
    }
}
