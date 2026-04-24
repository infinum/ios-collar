//
//  Collar.swift
//  Collar
//
//  Created by Filip Gulan on 06/03/2020.
//  Copyright © 2020 Infinum. All rights reserved.
//

import Foundation

/// Thread-safe analytics collection manager.
/// Internal thread safety is managed via a serial dispatch queue.
public final class AnalyticsCollectionManager: @unchecked Sendable {

    /// Notification name posted when logs are updated.
    /// - Important: Posted on the internal serial queue. Dispatch to the main queue
    ///   in your observer if you need to update UI.
    public enum Notification {
        public static let didUpdateLogs = Foundation.Notification.Name("AnalyticsCollectionManager.didUpdateLogs")
    }

    /// Shared instance for application-wide analytics collection.
    public static let shared = AnalyticsCollectionManager()

    private let queue = DispatchQueue(label: "com.infinum.collar.analytics", qos: .utility)
    private var _logs: [LogItem] = []

    private init() {}

    /// All collected log items. Awaits any pending writes before returning.
    public var logs: [LogItem] {
        get async {
            await withCheckedContinuation { continuation in
                queue.async { [weak self] in
                    guard let self else {
                        continuation.resume(returning: [])
                        return
                    }
                    continuation.resume(returning: _logs)
                }
            }
        }
    }

    // MARK: - Log Management

    /// Clears all collected logs.
    public func clearLogs() {
        queue.async { [weak self] in
            guard let self else { return }
            _logs.removeAll()
            postUpdateNotification()
        }
    }

    /// Removes a specific log item.
    /// - Parameter logItem: The log item to remove
    public func clearLog(_ logItem: LogItem) {
        queue.async { [weak self] in
            guard let self else { return }
            _logs.removeAll { $0.id == logItem.id }
            postUpdateNotification()
        }
    }

    // MARK: - Logging

    /// Tracks a screen view event.
    /// - Parameters:
    ///   - screenName: Name of the screen being viewed
    ///   - screenClass: Optional screen class identifier
    public func track(screenName: String?, screenClass: String? = nil) {
        guard let screenName else { return }
        queue.async { [weak self] in
            guard let self else { return }
            appendLog(LogItem(screenName: screenName, screenClass: screenClass))
        }
    }

    /// Sets a user property for analytics.
    /// - Parameters:
    ///   - value: Property value (nil to remove)
    ///   - name: Property name
    public func setUserProperty(_ value: String?, forName name: String) {
        queue.async { [weak self] in
            guard let self else { return }
            appendLog(LogItem(userProperty: name, value: value))
        }
    }

    /// Logs an analytics event with optional parameters.
    /// - Parameters:
    ///   - event: Event name (e.g., "button_tap", "screen_view")
    ///   - timestamp: Event timestamp (defaults to current time)
    ///   - parameters: Optional key-value pairs for event metadata
    public func log(event: String, timestamp: Date = Date(), parameters: [String: LoggerJsonValue]? = nil) {
        queue.async { [weak self] in
            guard let self else { return }
            appendLog(LogItem(event: event, timestamp: timestamp, parameters: parameters))
        }
    }

    // MARK: - Private helpers

    private func appendLog(_ log: LogItem) {
        _logs.append(log)
        postUpdateNotification()
    }

    private func postUpdateNotification() {
        NotificationCenter.default.post(name: AnalyticsCollectionManager.Notification.didUpdateLogs, object: nil)
    }
}
