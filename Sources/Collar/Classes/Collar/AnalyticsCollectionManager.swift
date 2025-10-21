//
//  Collar.swift
//  Collar
//
//  Created by Filip Gulan on 06/03/2020.
//  Copyright © 2020 Infinum. All rights reserved.
//

import Foundation

public final class AnalyticsCollectionManager: @unchecked Sendable {

    public enum Notification {
        public static var didUpdateLogs: Foundation.Notification {
            Foundation.Notification(name: .init("AnalyticsCollectionManager.didUpdateLogs"))
        }
    }

    public static let shared = AnalyticsCollectionManager()

    private let queue = DispatchQueue(label: "analytics.logs.queue", attributes: .concurrent)
    private var _logs: [LogItem] = []

    public var logs: [LogItem] {
        queue.sync { _logs }
    }

    // MARK: - Log Management

    public func clearLogs() {
        queue.async(flags: .barrier) {
            self._logs.removeAll()
            self.postUpdateNotification()
        }
    }

    public func clearLog(_ logItem: LogItem) {
        queue.async(flags: .barrier) {
            self._logs.removeAll { $0.id == logItem.id }
            self.postUpdateNotification()
        }
    }

    // MARK: - Logging

    public func track(screenName: String?, screenClass: String? = nil) {
        guard let screenName = screenName else { return }
        appendLog(LogItem(screenName: screenName, screenClass: screenClass))
    }

    public func setUserProperty(_ value: String?, forName name: String) {
        appendLog(LogItem(userProperty: name, value: value))
    }

    public func log(event: String, timestamp: Date = Date(), parameters: [String: LoggerJsonValue]? = nil) {
        appendLog(LogItem(event: event, timestamp: timestamp, parameters: parameters))
    }

    // MARK: - Private helpers

    private func appendLog(_ log: LogItem) {
        queue.async(flags: .barrier) {
            self._logs.append(log)
            self.postUpdateNotification()
        }
    }

    private func postUpdateNotification() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(AnalyticsCollectionManager.Notification.didUpdateLogs)
        }
    }
}
