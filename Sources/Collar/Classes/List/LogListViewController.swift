//
//  LogListViewController.swift
//
//  Created by Filip Gulan on 06/03/2020.
//  Copyright © 2020 Infinum. All rights reserved.
//

import UIKit

struct ScopeItem {
    let title: String
    let scopes: [LogType]

    static let all = ScopeItem(title: "All", scopes: [.event, .screen, .userProperty])
    static let events = ScopeItem(title: "Events", scopes: [.event])
    static let screens = ScopeItem(title: "Screens", scopes: [.screen])
    static let userProperties = ScopeItem(title: "User properties", scopes: [.userProperty])
}

public class LogListViewController: UITableViewController {

    // MARK: - Public properties -
    
    // MARK: - Private properties -

    private var targetLogs: [LogItem] {
        if isFiltering { return filteredLogs }
        else { return logs }
    }
    private var filteredLogs: [LogItem] = [] {
        didSet { tableView.reloadData() }
    }
    private var logs: [LogItem] = [] {
        didSet { tableView.reloadData() }
    }

    private static let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm:ss"
        return dateFormatter
    }()

    private var isSearchBarEmpty: Bool {
        return searchController.searchBar.text?.isEmpty ?? true
    }
    private var isFiltering: Bool {
        let searchBarScopeIsFiltering =
            searchController.searchBar.selectedScopeButtonIndex != 0
        return (searchController.isActive && !isSearchBarEmpty) || searchBarScopeIsFiltering
    }
    private let scopes: [ScopeItem] = [.all, .events, .screens, .userProperties]

    // MARK: - UI elements -

    private let searchController = UISearchController(searchResultsController: nil)

    // MARK: - Lifecycle -
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        title = "Logs"
        setupTableView()
        setupSearchController()
        setupCloseButton()
        setupSettingsButton()
        setupObservers()
        logsDidUpdate()
    }

    // MARK: - UITableViewDataSource

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return targetLogs.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(ofType: LogTableViewCell.self, for: indexPath)
        let dateInfo = LogListViewController.dateStringForItem(at: indexPath.row, logs: targetLogs)
        let index = indexPath.row
        let isFirstItem = index == 0
        let isLastItem = index == targetLogs.count - 1
        cell.configure(
            with: targetLogs[indexPath.row],
            dateInfo: dateInfo,
            showHeader: isFirstItem,
            showFooter: isLastItem
        )
        return cell
    }

    // MARK: - UITableViewDelegate

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let log = targetLogs[indexPath.row]
        showAlert(for: log)
    }

    public override func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    public override func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
    }

    public override func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        if action == #selector(copy(_:)) {
            let log = targetLogs[indexPath.row]
            UIPasteboard.general.string = log.description
        }
    }
}

extension LogListViewController: UISearchResultsUpdating, UISearchBarDelegate {

    public func updateSearchResults(for searchController: UISearchController) {
        filterLogs()
    }

    public func searchBar(_ searchBar: UISearchBar, selectedScopeButtonIndexDidChange selectedScope: Int) {
        filterLogs()
    }
}

private extension LogListViewController {
    
    func setupTableView() {
        tableView.separatorStyle = .none
        tableView.clipsToBounds = false
        tableView.estimatedRowHeight = 44
        tableView.registerNib(cellOfType: LogTableViewCell.self)
    }

    func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Filter logs"
        searchController.searchBar.scopeButtonTitles = scopes.map(\.title)
        searchController.searchBar.showsScopeBar = true
        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
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

    func filterLogs() {
        let searchText = searchController.searchBar.text ?? ""
        let scopeIndex = searchController.searchBar.selectedScopeButtonIndex
        if searchText.isEmpty && scopeIndex == 0 {
            filteredLogs = logs
            return
        }
        let scopeItem = scopes[scopeIndex]
        filteredLogs = filterLogs(with: searchText, scopeItem: scopeItem)
    }

    func filterLogs(with searchText: String, scopeItem: ScopeItem) -> [LogItem] {
        return logs.filter {
            let scopeMatches = scopeItem.scopes.contains($0.type)
            // Mini optimization to avoid text processing
            guard scopeMatches else { return false }
            // If empty, show all
            guard !isSearchBarEmpty else { return true }
            let normalizedSearchText = searchText
                .lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let matchesName: (LogItem) -> Bool = {
                return $0.name.lowercased().fuzzyMatch(normalizedSearchText)
            }
            let matchesValue: (LogItem) -> Bool = {
                return $0.value?.lowercased().fuzzyMatch(normalizedSearchText) ?? false
            }
            let matchesParams: (LogItem) -> Bool = {
                let params = $0.parameters ?? [:]
                return params.contains(where: {
                    $0.key.lowercased().fuzzyMatch(normalizedSearchText) ||
                    ($0.value as? String)?.lowercased().fuzzyMatch(normalizedSearchText) ?? false
                })
            }
            return matchesName($0) || matchesValue($0) || matchesParams($0)
        }
    }

    func showAlert(for log: LogItem) {
        let alert = UIAlertController(
            title: log.type.rawValue,
            message: log.description,
            preferredStyle: .alert
        )

        alert.addAction(.init(title: "Ok", style: .default))
        present(alert, animated: true)
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
        filterLogs()
    }
}

private extension String {

    /// Naive fuzzy match. Taken from: https://talk.objc.io/episodes/S01E211-simple-fuzzy-matching
    func fuzzyMatch(_ needle: String) -> Bool {
        if needle.isEmpty { return true }
        var remainder = needle[...]
        for char in self {
            if char == remainder[remainder.startIndex] {
                remainder.removeFirst()
                if remainder.isEmpty { return true }
            }
        }
        return false
    }
}
