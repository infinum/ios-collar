//
//  JSONLoggerValue.swift
//  Collar
//
//  Created by Petar Jadek on 21.10.2025.
//  Copyright © 2025 Infinum. All rights reserved.
//

import Foundation

public enum LoggerJsonValue: Sendable, Equatable {
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

    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }

    public init(arrayLiteral elements: LoggerJsonValue...) {
        self = .array(elements)
    }

    public init(dictionaryLiteral elements: (String, LoggerJsonValue)...) {
        self = .object(Dictionary(uniqueKeysWithValues: elements))
    }

    public init(_ uuid: UUID) {
        self = .string(uuid.uuidString)
    }
}

extension LoggerJsonValue {
    var jsonCompatible: Any {
        switch self {
        case .string(let s): s
        case .int(let i): i
        case .double(let d): d
        case .bool(let b): b
        case .array(let arr): arr.map { $0.jsonCompatible }
        case .object(let dict): dict.mapValues { $0.jsonCompatible }
        case .null: NSNull()
        }
    }
}
