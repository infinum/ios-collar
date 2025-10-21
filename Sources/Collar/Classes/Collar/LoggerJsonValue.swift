//
//  JSONLoggerValue.swift
//  Collar
//
//  Created by Petar Jadek on 21.10.2025.
//  Copyright © 2025 Infinum. All rights reserved.
//

import Foundation

public enum LoggerJsonValue: Sendable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([LoggerJsonValue])
    case object([String: LoggerJsonValue])
    case null
}

extension LoggerJsonValue: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByBooleanLiteral,
                         ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral {

    public init(stringLiteral value: String) {
        self = .string(value)
    }

    public init(integerLiteral value: Int) {
        self = .int(value)
    }

    public init(
        booleanLiteral value: Bool) { self = .bool(value)
    }

    public init(arrayLiteral elements: LoggerJsonValue...) {
        self = .array(elements)
    }

    public init(dictionaryLiteral elements: (String, LoggerJsonValue)...) {
        self = .object(Dictionary(uniqueKeysWithValues: elements))
    }
}

extension LoggerJsonValue {
    var jsonCompatible: Any {
        switch self {
        case .string(let s): return s
        case .int(let i): return i
        case .double(let d): return d
        case .bool(let b): return b
        case .array(let arr): return arr.map { $0.jsonCompatible }
        case .object(let dict): return dict.mapValues { $0.jsonCompatible }
        case .null: return NSNull()
        }
    }
}
