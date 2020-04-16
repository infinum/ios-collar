//
//  LogItemPopupQueue.swift
//  AnalyticsCollector
//
//  Created by Filip Gulan on 17/03/2020.
//  Copyright © 2020 Infinum. All rights reserved.
//

import UIKit

public class LogItemPopupQueue {
    
    // MARK: - Public properties
    
    public static let shared = LogItemPopupQueue()
    
    public var popupDuration: TimeInterval = 2
    
    public var showOnView: (() -> UIView?)?
    
    // MARK: - Internal properties
    
    public var enabled: Bool {
        get { UserDefaults.standard.bool(forKey: Constants.enabledUserDefaultsKey) }
        set { UserDefaults.standard.set(newValue, forKey: Constants.enabledUserDefaultsKey) }
    }
    
    // MARK: - Private properties
    
    private var visiblePopupView: UIView?
    private var currentTimer: Timer?
    
    private var itemsToShow: [LogItem] = [] {
        didSet { showPopupIfPossible() }
    }
    
    private init() { }
    
    internal func show(_ logItem: LogItem) {
        guard enabled else { return }
        itemsToShow.append(logItem)
    }
}

private extension LogItemPopupQueue {
    
    enum Constants {
        static let enabledUserDefaultsKey = "com.infinum.analytics-collector.popup.enabled"
    }
    
    func showPopupIfPossible() {
        guard
            enabled,
            visiblePopupView == nil,
            let itemToShow = itemsToShow.first
        else { return }
        
        display(itemToShow)
        
        currentTimer = Timer.scheduledTimer(withTimeInterval: popupDuration, repeats: false) { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                // This will remove first element and trigger didSet which
                // will call this method again, but before that remove current visible
                // popup so that guard will pass
                UIView.animate(
                    withDuration: 0.3,
                    animations: { [weak self] in self?.visiblePopupView?.alpha = 0.0 },
                    completion: { [weak self] _ in
                        guard let self = self else { return }
                        self.currentTimer = nil
                        self.visiblePopupView?.removeFromSuperview()
                        self.visiblePopupView = nil
                        if !self.itemsToShow.isEmpty {
                            self.itemsToShow.removeFirst()
                        }
                    })
            }
        }
    }
    
    func display(_ logItem: LogItem) {
        guard let parentView = showOnView?() else { return }
        
        let popupView = LogItemPopupView.fromNib()
        popupView.configure(with: logItem)
        popupView.translatesAutoresizingMaskIntoConstraints = false
        popupView.dismissPopup = { [weak self] in
            guard let self = self else { return }
            self.currentTimer?.invalidate()
            self.currentTimer = nil
            self.visiblePopupView?.removeFromSuperview()
            self.visiblePopupView = nil
            if !self.itemsToShow.isEmpty {
                self.itemsToShow.removeFirst()
            }
        }
        
        parentView.addSubview(popupView)
        
        NSLayoutConstraint.activate([
            popupView.leadingAnchor
                .constraint(equalTo: parentView.saferAreaLayoutGuide.leadingAnchor, constant: 24),
            popupView.trailingAnchor
                .constraint(equalTo: parentView.saferAreaLayoutGuide.trailingAnchor, constant: -24),
            popupView.bottomAnchor
                .constraint(equalTo: parentView.saferAreaLayoutGuide.bottomAnchor, constant: -80)
        ])
        parentView.bringSubviewToFront(popupView)
        
        popupView.alpha = 0
        UIView.animate(withDuration: 0.3) {
            popupView.alpha = 1
        }
        visiblePopupView = popupView
    }
}
