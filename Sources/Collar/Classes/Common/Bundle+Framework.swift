//
//  Bundle+Framework.swift
//  Collar
//
//  Created by Filip Gulan on 11/04/2020.
//

import Foundation

extension Bundle {
    
    static var framework: Bundle {
        let bundle = Bundle(for: LogListViewController.self)
        if
            let path = bundle.path(forResource: "Collar", ofType: "bundle"),
            let customBundle = Bundle(path: path)
        {
            return customBundle
        }
        return bundle
    }
}
