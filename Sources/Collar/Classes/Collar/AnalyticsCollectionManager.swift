//
//  Collar.swift
//  Collar
//
//  Created by Filip Gulan on 06/03/2020.
//  Copyright © 2020 Infinum. All rights reserved.
//

import Foundation

/// Actor-based analytics collection manager providing thread-safe log management.
/// All methods are async and must be awaited. Actor isolation provides compiler-verified thread safety.
public actor AnalyticsCollectionManager {

    /// Notifications posted when logs are updated.
    /// - Important: Notifications are posted on the actor's internal queue.
    ///   If you need to update UI in response to this notification,
    ///   dispatch to the main queue in your observer using Task { @MainActor in ... }.
    public enum Notification {
        public static var didUpdateLogs: Foundation.Notification {
            Foundation.Notification(name: .init("AnalyticsCollectionManager.didUpdateLogs"))
        }
    }

    /// Shared instance for application-wide analytics collection.
    /// Thread-safe access through actor isolation.
    public static let shared = AnalyticsCollectionManager()

    private var _logs: [LogItem] = []

    /// All collected log items.
    /// - Returns: Array of log items in chronological order
    /// - Note: This is an async operation that suspends until the actor can provide safe access
    public var logs: [LogItem] {
        get async {
            _logs
        }
    }

    // MARK: - Log Management

    /// Clears all collected logs.
    /// - Note: This method is async and must be awaited
    public func clearLogs() async {
        _logs.removeAll()
        postUpdateNotification()
    }

    /// Removes a specific log item.
    /// - Parameter logItem: The log item to remove
    /// - Note: This method is async and must be awaited
    public func clearLog(_ logItem: LogItem) async {
        _logs.removeAll { $0.id == logItem.id }
        postUpdateNotification()
    }

    // MARK: - Logging

    /// Tracks a screen view event.
    /// - Parameters:
    ///   - screenName: Name of the screen being viewed
    ///   - screenClass: Optional screen class identifier
    /// - Note: This method is async and must be awaited
    public func track(screenName: String?, screenClass: String? = nil) async {
        guard let screenName = screenName else { return }
        appendLog(LogItem(screenName: screenName, screenClass: screenClass))
    }

    /// Sets a user property for analytics.
    /// - Parameters:
    ///   - value: Property value (nil to remove)
    ///   - name: Property name
    /// - Note: This method is async and must be awaited
    public func setUserProperty(_ value: String?, forName name: String) async {
        appendLog(LogItem(userProperty: name, value: value))
    }

    /// Logs an analytics event with optional parameters.
    /// - Parameters:
    ///   - event: Event name (e.g., "button_tap", "screen_view")
    ///   - timestamp: Event timestamp (defaults to current time)
    ///   - parameters: Optional key-value pairs for event metadata
    /// - Note: This method is async and must be awaited
    public func log(event: String, timestamp: Date = Date(), parameters: [String: LoggerJsonValue]? = nil) async {
        appendLog(LogItem(event: event, timestamp: timestamp, parameters: parameters))
    }

    // MARK: - Private helpers

    private func appendLog(_ log: LogItem) {
        _logs.append(log)
        postUpdateNotification()
    }

    private func postUpdateNotification() {
        NotificationCenter.default.post(AnalyticsCollectionManager.Notification.didUpdateLogs)
    }
}
