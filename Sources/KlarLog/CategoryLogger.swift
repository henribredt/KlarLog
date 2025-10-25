//
//  File.swift
//  KlarLog
//
//  Created by Henri Bredt on 25.10.25.
//

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

/// A lightweight proxy that wraps a `CategoryLogger` for a specific subsystem and exposes
/// convenience APIs for logging at different levels (e.g., `debug`, `info`, `error`).
///
/// Use instances of `Category` to write logs with a preconfigured subsystem and category.
/// You typically obtain a `Category` from `TypedLogger` via dynamic member lookup.
public struct Category {
    /// Log severity levels supported by `Category`.
    public enum Level: String {
        case debug, info, notice, warning, error, critical
    }
    
    private let subsystem: () -> String
    private var base: CategoryLogger
    
    /// Creates a new category proxy.
    /// - Parameters:
    ///   - subsystem: A closure that returns the current subsystem string.
    ///   - base: The underlying `CategoryLogger` that performs the actual logging.
    public init(subsystem: @escaping () -> String, base: CategoryLogger) {
        self.subsystem = subsystem
        self.base = base
    }
    
    /// Logs a message at a given level.
    /// - Parameters:
    ///   - level: The severity level of the message.
    ///   - message: The text to be logged.
    private func log(_ level: Level, _ message: String) {
        base.log(subsystem: subsystem(), level: level, message: message)
    }
    
    // MARK: - Convenience methods
    
    public func debug(_ message: String) {
        self.log(.debug, message)
    }
    
    public func info(_ message: String) {
        self.log(.info, message)
    }
    
    public func notice(_ message: String) {
        self.log(.notice, message)
    }
    
    public func warning(_ message: String) {
        self.log(.warning, message)
    }
    
    public func error(_ message: String) {
        self.log(.error, message)
    }
    
    public func critical(_ message: String) {
        self.log(.critical, message)
    }
}
