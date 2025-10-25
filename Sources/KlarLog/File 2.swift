//
//  File 2.swift
//  KlarLog
//
//  Created by Henri Bredt on 25.10.25.
//

import Foundation
import OSLog

public protocol LogDestination {
    func log(subsystem: String, category: String, level: Category.Level, message: String)
}

// MARK: - Destination-backed category logger
public struct CategoryLogger {
    public let category: String
    private var destinations: [LogDestination]

    public init(category: String, destinations: [LogDestination] = []) {
        self.category = category
        self.destinations = destinations
    }

    public mutating func addDestination(_ destination: LogDestination) {
        destinations.append(destination)
    }

    public func log(subsystem: String, level: Category.Level, message: String) {
        destinations.forEach { $0.log(subsystem: subsystem, category: category, level: level, message: message) }
    }
}

// MARK: - Category proxy with levels
public struct Category {
    public enum Level: String { case debug, info, notice, warning, error, critical }

    private let subsystem: () -> String
    private var base: CategoryLogger

    public init(subsystem: @escaping () -> String, base: CategoryLogger) {
        self.subsystem = subsystem
        self.base = base
    }

    public func log(_ level: Level, _ message: String) {
        base.log(subsystem: subsystem(), level: level, message: message)
    }

    public func callAsFunction(_ message: String) { log(.info, message) }

    public var debug: (String) -> Void { { msg in self.log(.debug, msg) } }
    public var info: (String) -> Void { { msg in self.log(.info, msg) } }
    public var notice: (String) -> Void { { msg in self.log(.notice, msg) } }
    public var warning: (String) -> Void { { msg in self.log(.warning, msg) } }
    public var error: (String) -> Void { { msg in self.log(.error, msg) } }
    public var critical: (String) -> Void { { msg in self.log(.critical, msg) } }
}

// MARK: - Default destination
public struct ConsoleDestination: LogDestination {
    public init() {}
    public func log(subsystem: String, category: String, level: Category.Level, message: String) {
        let logger = os.Logger(subsystem: subsystem, category: category)
        switch level {
        case .debug:
            logger.debug("\(message)")
        case .info:
            logger.info("\(message)")
        case .notice:
            logger.notice("\(message)")
        case .warning:
            logger.warning("\(message)")
        case .error:
            logger.error("\(message)")
        case .critical:
            logger.critical("\(message)")
        }
    }
}

@dynamicMemberLookup
public final class TypedLogger<Registry> {
    private var registry: Registry
    public var subsystem: String

    public init(with registry: Registry, subsystem: String) {
        self.registry = registry
        self.subsystem = subsystem
    }

    public subscript<T>(dynamicMember keyPath: KeyPath<Registry, T>) -> T {
        registry[keyPath: keyPath]
    }

    public subscript<T>(dynamicMember keyPath: WritableKeyPath<Registry, T>) -> T {
        get { registry[keyPath: keyPath] }
        set { registry[keyPath: keyPath] = newValue }
    }
}

public extension TypedLogger where Registry == CategoryLoggers {
    subscript(dynamicMember keyPath: KeyPath<CategoryLoggers, CategoryLogger>) -> Category {
        let base = registry[keyPath: keyPath]
        return Category(subsystem: { [weak self] in self?.subsystem ?? "" }, base: base)
    }

    subscript(dynamicMember keyPath: WritableKeyPath<CategoryLoggers, CategoryLogger>) -> Category {
        let base = registry[keyPath: keyPath]
        return Category(subsystem: { [weak self] in self?.subsystem ?? "" }, base: base)
    }
}


