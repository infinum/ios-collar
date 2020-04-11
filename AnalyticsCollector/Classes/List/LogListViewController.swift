//
//  LogListViewController.swift
//
//  Created by Filip Gulan on 06/03/2020.
//  Copyright © 2020 Infinum. All rights reserved.
//

import UIKit

public class LogListViewController: UITableViewController {

    // MARK: - Public properties -
    
    // MARK: - Private properties -
    
    private var logs: [LogItem] = [] {
        didSet { tableView.reloadData() }
    }
    
    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        return dateFormatter
    }()

    // MARK: - Lifecycle -
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        title = "Logs"
        setupTableView()
        setupCloseButton()
        setupSettingsButton()
        setupObservers()
        logsDidUpdate()
    }
    
    // MARK: - UITableViewDataSource
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logs.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(ofType: LogTableViewCell.self, for: indexPath)
        let dateInfo = LogListViewController.dateStringForItem(at: indexPath.row, logs: logs)
        cell.configure(with: logs[indexPath.row], dateInfo: dateInfo)
        return cell
    }
    
    // MARK: - UITableViewDelegate
    
    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

private extension LogListViewController {
    
    func setupTableView() {
        tableView.separatorStyle = .none
        tableView.clipsToBounds = false
        tableView.estimatedRowHeight = 44
        tableView.tableHeaderView = LogHeaderFooterView(height: 32, bulletType: .top)
        tableView.tableFooterView = LogHeaderFooterView(height: 32, bulletType: .bottom)
        tableView.registerNib(cellOfType: LogTableViewCell.self)
    }
    
    func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(logsDidUpdate),
            name: AnalyticsCollectionManager.Notification.didUpdateLogs.name,
            object: nil
        )
    }
    
    func setupCloseButton() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .stop,
            target: self,
            action: #selector(closeButtonActionHandler)
        )
    }
    
    func setupSettingsButton() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Settings",
            style: .plain,
            target: self,
            action: #selector(settingsButtonActionHandler)
        )
    }
    
    static func dateStringForItem(at index: Int, logs: [LogItem]) -> String? {
        guard index > 0 else {
            return dateFormatter.string(from: logs[index].timestamp)
        }
        let item = logs[index]
        // Here we are safe that index is >= 1
        let previousItem = logs[index - 1]
        let areInSameSecond = Calendar.current
            .isDate(item.timestamp, equalTo: previousItem.timestamp, toGranularity: .second)
        
        return areInSameSecond ? nil : dateFormatter.string(from: item.timestamp)
    }
}

// MARK: - Action handlers -

private extension LogListViewController {
    
    @objc
    func closeButtonActionHandler() {
        dismiss(animated: true)
    }
    
    @objc
    func settingsButtonActionHandler() {
        let settingsViewController = SettingsViewController.fromStoryboard()
        let navigationController = UINavigationController(rootViewController: settingsViewController)
        present(navigationController, animated: true)
    }
    
    @objc
    func logsDidUpdate() {
        logs = AnalyticsCollectionManager.shared
            .logs
            .sorted(by: { $0.timestamp > $1.timestamp })
    }
}
