//
//  LogDestination.swift
//  KlarLog
//

import Foundation

/// A type that receives and processes log messages from `CategoryLogger` instances.
///
/// Conform to `LogDestination` to create custom log handlers that route messages
/// to different outputs (e.g., console, file, remote server, analytics service).
///
/// The `CategoryLogger` routes each log message to all of its configured destinations,
/// allowing you to send logs to multiple outputs simultaneously.
///
/// KlarLog provides build destinations like `ConsoleDestination`s.
public protocol LogDestination {
    /// Processes a log message with full context information.
    ///
    /// This method is called by `CategoryLogger` for each configured destination
    /// when a log message is written.
    ///
    /// - Parameters:
    ///   - subsystem: The subsystem identifier (e.g., "com.example.app").
    ///   - category: The category name (e.g., "network", "database").
    ///   - level: The severity level of the message.
    ///   - message: The message text to log.
    func log(subsystem: String, category: String, level: ExposedCategoryLogger.Level, message: String)
}
