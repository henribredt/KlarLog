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
/// ## Built-in Destinations
///
/// KlarLog provides:
/// - `ConsoleDestination` - Writes to the system console using `os.Logger`
/// - `LocalFileDestination` - Writes to a local file
///
/// ## Custom Destinations
///
/// Create custom destinations by conforming to this protocol:
///
/// ```swift
/// struct AnalyticsDestination: LogDestination, Sendable {
///     // Required from `LogDestination` protocol:
///     // Only messages whose level is included in this collection should be handled.
///     public var logForLogLevels: [LogLevel]
///
///     /// Creates a console logging destination.
///     /// - Parameter logForLogLevels: The log levels this destination should write. Messages whose level is not included are ignored. Defaults to all log levels.
///     public init(logForLogLevels: [LogLevel] = LogLevel.allCases) {
///         self.logForLogLevels = logForLogLevels
///     }
///
///     func log(subsystem: String, category: String, level: LogLevel, message: String) {
///         // Only perform the action of this destination if it was configured to act on this log level.
///         guard logForLogLevels.contains(level) else {
///             return
///         }
///
///         // perfom custom actions, e.g.:
///         Analytics.track(event: "log", properties: [
///             "level": level.rawValue,
///             "category": category,
///             "message": message
///         ])
///     }
/// }
/// ```
/// - Important: In your custom `LogDestination` implementation you are responsible for implementing
///  `logForLogLevels` checks and only acting on log messages that are included in the
///  `logForLogLevels` configuration.
public protocol LogDestination: Sendable {
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
    func log(subsystem: String, category: String, level: LogLevel, message: String)

    /// Processes a log message with structured metadata.
    ///
    /// This method is called by `CategoryLogger` when a log message includes
    /// structured metadata. By default, this strips the metadata and calls
    /// the basic `log(subsystem:category:level:message:)` method.
    ///
    /// Override this method in your destination to handle structured metadata.
    ///
    /// - Parameters:
    ///   - subsystem: The subsystem identifier (e.g., "com.example.app").
    ///   - category: The category name (e.g., "network", "database").
    ///   - level: The severity level of the message.
    ///   - message: The message text to log.
    ///   - metadata: Structured data associated with this log entry.
    func log(subsystem: String, category: String, level: LogLevel, message: String, metadata: LogMetadata?)

    /// The log levels that this destination should emit.
    ///
    /// Use this to filter which messages a destination processes. Messages whose
    /// `level` is not included should be ignored by the destination.
    ///
    /// It's recommended to use a `guard` check in the `LogDestination` implementation:
    /// ```swift
    /// public struct CustomDestination: LogDestination, Sendable {
    ///     // Only messages whose level is included in this collection should be handled.
    ///     public var logForLogLevels: [ExposedCategoryLogger.Level]
    ///
    ///     public func log(subsystem: String, category: String, level: LogLevel, message: String) {
    ///         // Only perform the action of this destination if it was configured to act on this log level.
    ///         guard logForLogLevels.contains(level) else {
    ///             return
    ///         }
    ///         // perform your actions ...
    ///     }
    /// }
    ///  ```
    /// - Important: In your custom `LogDestination` implementation you are responsible for implementing this behaviour.
    var logForLogLevels: [LogLevel] { get }
}

// MARK: - Default Implementation

public extension LogDestination {
    /// Default implementation that strips metadata and calls the basic log method.
    ///
    /// Custom destinations can override this to handle metadata appropriately.
    func log(subsystem: String, category: String, level: LogLevel, message: String, metadata: LogMetadata?) {
        // By default, ignore metadata and call the basic log method
        log(subsystem: subsystem, category: category, level: level, message: message)
    }
}

