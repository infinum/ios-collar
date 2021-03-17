//
//  LogItemPopupView.swift
//  Collar
//
//  Created by Filip Gulan on 18/03/2020.
//  Copyright © 2020 Infinum. All rights reserved.
//

import UIKit

class LogItemPopupView: UIView {
    
    // MARK: - Internal properties
    
    internal var dismissPopup: (() -> (Void))?
    
    // MARK: - IBOutlets
    
    @IBOutlet private weak var titleLabel: UILabel!
    @IBOutlet private weak var subtitleLabel: UILabel!
    @IBOutlet private weak var typeImageView: UIImageView!
    
    // MARK: - Lifecycle

    static func fromNib() -> LogItemPopupView {
        return Bundle.framework
            .loadNibNamed("LogItemPopupView", owner: nil, options: nil)!
            .first as! LogItemPopupView
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 8
        layer.masksToBounds = true
        setupTapGesture()
    }
    
    func configure(with logItem: LogItem) {
        titleLabel.text = logItem.name
        subtitleLabel.text = logItem.subtitleDisplay
        typeImageView.image = logItem.coloredImage
        hideLabelsIfNeeded()
    }
}

private extension LogItemPopupView {
    
    func setupTapGesture() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTapOnPopupActionHandler))
        addGestureRecognizer(tapGestureRecognizer)
    }
    
    @objc
    func didTapOnPopupActionHandler() {
        dismissPopup?()
    }
    
    func hideLabelsIfNeeded() {
        titleLabel.hiddenSafelyIfNeeded()
        subtitleLabel.hiddenSafelyIfNeeded()
    }
}

