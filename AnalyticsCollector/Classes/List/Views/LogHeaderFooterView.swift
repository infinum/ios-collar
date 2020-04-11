//
//  LogHeaderFooterView.swift
//  AnalyticsCollector
//
//  Created by Filip Gulan on 06/03/2020.
//  Copyright © 2020 Infinum. All rights reserved.
//

import UIKit

class LogHeaderFooterView: UIView {
    
    enum BulletType {
        case top, bottom
    }
        
    init(height: CGFloat, bulletType: BulletType, color: UIColor = .init(white: 0.8, alpha: 1)) {
        super.init(frame: .init(origin: .zero, size: .init(width: 0, height: height)))
        setupView(height: height, bulletType: bulletType, color: color)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension LogHeaderFooterView {
    
    func setupView(height: CGFloat, bulletType: BulletType, color: UIColor) {
        let inset: CGFloat = 4
        let line = setupLine(type: bulletType, color: color, inset: inset)
        setupBullet(type: bulletType, line: line, color: color)
        heightAnchor.constraint(equalToConstant: height).isActive = true
        
        layer.shadowColor = UIColor.lightGray.cgColor
        layer.shadowOpacity = 0.4
        layer.shadowOffset = .init(width: 1, height: 2)
        layer.shadowRadius = 1
    }
    
    func setupLine(type: BulletType, color: UIColor, inset: CGFloat) -> UIView {
        let line = UIView()
        line.translatesAutoresizingMaskIntoConstraints = false
        addSubview(line)
        let isTop = type == .top
        NSLayoutConstraint.activate([
            line.topAnchor.constraint(equalTo: topAnchor, constant: isTop ? inset : 0),
            line.bottomAnchor.constraint(equalTo: bottomAnchor, constant: isTop ? 0 : inset),
            line.leadingAnchor.constraint(equalTo: saferAreaLayoutGuide.leadingAnchor, constant: 95),
            line.widthAnchor.constraint(equalToConstant: 2)
        ])
        line.backgroundColor = color
        return line
    }
    
    func setupBullet(type: BulletType, line: UIView, color: UIColor) {
        let bullet = UIView()
        bullet.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bullet)
        let verticalConstraint = type == .top ?
            bullet.topAnchor.constraint(equalTo: line.topAnchor) :
            bullet.bottomAnchor.constraint(equalTo: line.bottomAnchor)
        
        let size: CGFloat = 16
        NSLayoutConstraint.activate([
            verticalConstraint,
            bullet.centerXAnchor.constraint(equalTo: line.centerXAnchor),
            bullet.widthAnchor.constraint(equalToConstant: size),
            bullet.heightAnchor.constraint(equalToConstant: size)
        ])
    
        bullet.layer.masksToBounds = true
        bullet.layer.cornerRadius = size / 2
        bullet.backgroundColor = color
    }
}
