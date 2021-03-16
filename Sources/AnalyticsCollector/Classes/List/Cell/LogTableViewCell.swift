//
//  AnalyticsLogTableViewCell.swift
//  AnalyticsCollector
//
//  Created by Filip Gulan on 06/03/2020.
//  Copyright © 2020 Infinum. All rights reserved.
//

import UIKit

class LogTableViewCell: UITableViewCell {

    // MARK: - IBOutlets
    
    @IBOutlet private weak var dateLabel: UILabel!
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var typeImageView: UIImageView!
    @IBOutlet private weak var lineContainerView: UIView!

    @IBOutlet private weak var headerContainerView: UIView!
    @IBOutlet private weak var footerContainerView: UIView!
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addShadow(to: lineContainerView)
        setupHeaderAndFooterViews()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        dateLabel.text = nil
        titleLabel.text = nil
        subtitleLabel.text = nil
        typeImageView.image = nil
        hideLabelsIfNeeded()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        typeImageView.layer.cornerRadius = typeImageView.bounds.width / 2
    }
    
    func configure(with logItem: LogItem, dateInfo: String?, showHeader: Bool, showFooter: Bool) {
        titleLabel.text = logItem.name
        subtitleLabel.text = logItem.subtitleDisplay
        typeImageView.image = logItem.coloredImage
        dateLabel.text = dateInfo
        headerContainerView.hiddenSafely = !showHeader
        footerContainerView.hiddenSafely = !showFooter
        hideLabelsIfNeeded()
    }
}

private extension LogTableViewCell {
    
    func hideLabelsIfNeeded() {
        dateLabel.hiddenSafelyIfNeeded()
        titleLabel.hiddenSafelyIfNeeded()
        subtitleLabel.hiddenSafelyIfNeeded()
    }
    
    func addShadow(to view: UIView) {
        view.layer.shadowColor = UIColor.lightGray.cgColor
        view.layer.shadowOpacity = 0.4
        view.layer.shadowOffset = .init(width: 1, height: 2)
        view.layer.shadowRadius = 1
    }

    func setupHeaderAndFooterViews() {
        let headerView = LogHeaderFooterView(height: 32, bulletType: .top)
        headerContainerView.addSubview(headerView)
        NSLayoutConstraint.activate([
            headerView.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),
            headerView.topAnchor.constraint(equalTo: headerContainerView.topAnchor),
            headerView.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor)
        ])

        let footerView = LogHeaderFooterView(height: 32, bulletType: .bottom)
        footerContainerView.addSubview(footerView)
        NSLayoutConstraint.activate([
            footerView.leadingAnchor.constraint(equalTo: footerContainerView.leadingAnchor),
            footerView.trailingAnchor.constraint(equalTo: footerContainerView.trailingAnchor),
            footerView.topAnchor.constraint(equalTo: footerContainerView.topAnchor),
            footerView.bottomAnchor.constraint(equalTo: footerContainerView.bottomAnchor)
        ])

        headerContainerView.hiddenSafely = false
        footerContainerView.hiddenSafely = false
    }
}

// MARK: - Helpers

extension UILabel {
    
    /// Hides label if text is empty or nil
    func hiddenSafelyIfNeeded() {
        hiddenSafely = (text ?? "").isEmpty
    }
}

extension UIView {

    var hiddenSafely: Bool {
        get { isHidden }
        set(hidden) { if hidden != isHidden { isHidden.toggle() } }
    }
}

extension LogItem {
    
    var subtitleDisplay: String? {
        switch type {
        case .event:
            return paramsJSONString
        case .userProperty, .screen:
            return value
        }
    }
    
    var coloredImage: UIImage? {
        let imageName: String
        switch type {
        case .event:
            imageName = "ic-touch-event"
        case .screen:
            imageName = "ic-screen-event"
        case .userProperty:
            imageName = "ic-user-property"
        }
        return UIImage(named: imageName, in: .framework, compatibleWith: nil)
    }
}
